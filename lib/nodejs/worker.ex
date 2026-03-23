defmodule NodeJS.Worker do
  use GenServer

  # Port can't do more than this.
  @read_chunk_size 65_536

  # This random looking string makes sure that other things writing to
  # stdout do not interfere with the protocol that we rely on here.
  # All protocol messages start with this string.
  @prefix ~c"__elixirnodejs__UOSBsDUP6bp9IF5__"

  @moduledoc """
  A genserver that controls the starting of the node service
  """
  require Logger

  @doc """
  Starts the Supervisor and underlying node service.
  """
  @spec start_link([binary()], any()) :: {:ok, pid} | {:error, any()}
  def start_link([module_path], opts \\ []) do
    GenServer.start_link(__MODULE__, module_path, name: Keyword.get(opts, :name))
  end

  # Node.js REPL Service
  defp node_service_path() do
    Path.join(:code.priv_dir(:nodejs), "server.js")
  end

  # Specifies the NODE_PATH for the REPL service to require modules from. We specify
  # both the root path and `/node_modules` folder relative to the root path. This is
  # to specify the entry point that the REPL service runs code from.
  defp node_path(module_path) do
    [module_path, module_path <> "/node_modules"]
    |> Enum.join(node_path_separator())
    |> String.to_charlist()
  end

  defp node_path_separator do
    case :os.type() do
      {:win32, _} -> ";"
      _ -> ":"
    end
  end

  # --- GenServer Callbacks ---
  @doc false
  def init(module_path) do
    node = Application.get_env(:nodejs, :executable_path) || System.find_executable("node")

    port =
      Port.open(
        {:spawn_executable, node},
        [
          {:line, @read_chunk_size},
          {:env, get_env_vars(module_path)},
          {:args, [node_service_path()]},
          :exit_status,
          :stderr_to_stdout
        ]
      )

    {:ok, %{service_path: node_service_path(), port: port, uid_counter: 0}}
  end

  defp get_env_vars(module_path) do
    [
      {~c"NODE_PATH", node_path(module_path)},
      {~c"WRITE_CHUNK_SIZE", String.to_charlist("#{@read_chunk_size}")}
    ]
  end

  defp get_response(data, timeout, port, expected_uid) do
    receive do
      {^port, {:data, {flag, chunk}}} ->
        data = data ++ chunk

        case flag do
          :noeol ->
            get_response(data, timeout, port, expected_uid)

          :eol ->
            case data do
              @prefix ++ protocol_data ->
                case extract_uid(protocol_data) do
                  {^expected_uid, response_data} ->
                    {:ok, response_data}

                  {_stale_uid, _response_data} ->
                    # Response from a different (likely timed-out) request — discard it
                    get_response(~c"", timeout, port, expected_uid)
                end

              _ ->
                get_response(~c"", timeout, port, expected_uid)
            end
        end

      {^port, {:exit_status, status}} when status != 0 ->
        {:error, {:exit, status}}
    after
      timeout -> {:error, :timeout}
    end
  end

  # Extracts the UID and response data from protocol data.
  # Protocol format: "uid:json_response"
  defp extract_uid(data) do
    case Enum.split_while(data, &(&1 != ?:)) do
      {uid_chars, [?: | rest]} -> {List.to_string(uid_chars), rest}
      _ -> {"", data}
    end
  end

  defp decode_binary(data, binary) do
    if binary === true do
      :binary.list_to_bin(data)
    else
      data
    end
  end

  @doc false
  def handle_call({module, args, opts}, _from, %{port: port, uid_counter: uid_counter} = state)
      when is_tuple(module) do
    timeout = Keyword.get(opts, :timeout)
    binary = Keyword.get(opts, :binary)
    esm = Keyword.get(opts, :esm, false)
    uid = Integer.to_string(uid_counter)
    body = Jason.encode!([uid, Tuple.to_list(module), args, esm])
    Port.command(port, "#{body}\n")

    state = %{state | uid_counter: uid_counter + 1}

    case get_response(~c"", timeout, port, uid) do
      {:ok, response} ->
        decoded_response =
          response
          |> decode_binary(binary)
          |> decode()

        {:reply, decoded_response, state}

      {:error, :timeout} ->
        {:reply, {:error, :timeout}, state}
    end
  end

  # Determines if debug mode is enabled via application configuration
  defp debug_mode? do
    Application.get_env(:nodejs, :debug_mode, false)
  end

  # Handles any messages from the Node.js process
  # When debug_mode is enabled, these messages (like Node.js debug info)
  # will be logged at info level
  @doc false
  def handle_info({_pid, {:data, {_flag, msg}}}, state) do
    if debug_mode?() do
      Logger.info("NodeJS: #{msg}")
    end

    {:noreply, state}
  end

  # Catch-all handler for other messages
  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp decode(data) do
    data
    |> to_string()
    |> Jason.decode!()
    |> case do
      [true, success] -> {:ok, success}
      [false, error] -> {:error, error}
    end
  end

  # Safely resets the terminal, handling potential errors if
  # the port is already closed or invalid
  defp reset_terminal(port) do
    try do
      Port.command(port, "\x1b[0m\x1b[?7h\x1b[?25h\x1b[H\x1b[2J")
      Port.command(port, "\x1b[!p\x1b[?47l")
    rescue
      _ ->
        Logger.debug("NodeJS: Could not reset terminal - port may be closed")
    end
  end

  @doc false
  def terminate(_reason, %{port: port}) do
    reset_terminal(port)
    send(port, {self(), :close})
  end
end
