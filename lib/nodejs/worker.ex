defmodule NodeJS.Worker do
  use GenServer

  # Port can't do more than this.
  @read_chunk_size 65_536

  # This random looking string makes sure that other things writing to
  # stdout do not interfere with the protocol that we rely on here.
  # All protocol messages start with this string.
  @prefix '__elixirnodejs__UOSBsDUP6bp9IF5__'

  @moduledoc """
  A genserver that controls the starting of the node service
  """

  @doc """
  Starts the Supervisor and underlying node service.
  """
  @spec start_link([binary()], any()) :: {:ok, pid} | {:error, any()}
  def start_link([module_path, unsecure_tls, proxy_settings], opts \\ []) do
    GenServer.start_link(__MODULE__, [module_path, unsecure_tls, proxy_settings], name: Keyword.get(opts, :name))
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
  def init([module_path, unsecure_tls, proxy_settings]) do
    node = System.find_executable("node")

    port =
      Port.open(
        {:spawn_executable, node},
        line: @read_chunk_size,
        env: get_env_options(module_path, unsecure_tls, proxy_settings),
        args: [node_service_path()]
      )

    {:ok, [node_service_path(), port]}
  end

  defp get_response(data, timeout) do
    receive do
      {_, {:data, {flag, chunk}}} ->
        data = data ++ chunk

        case flag do
          :noeol ->
            get_response(data, timeout)

          :eol ->
            case data do
              @prefix ++ protocol_data ->
                {:ok, protocol_data}

              _ ->
                get_response('', timeout)
            end
        end
    after
      timeout ->
        {:error, :timeout}
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
  def handle_call({module, args, opts}, _from, [_, port] = state)
      when is_tuple(module) do
    timeout = Keyword.get(opts, :timeout)
    binary = Keyword.get(opts, :binary)

    body = :jiffy.encode([Tuple.to_list(module), args], [:use_nil])
    Port.command(port, "#{body}\n")

    case get_response('', timeout) do
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

  defp decode(data) do
    data
    |> to_string()
    |> :jiffy.decode([:return_maps, :use_nil])
    |> case do
      [true, success] -> {:ok, success}
      [false, error] -> {:error, error}
    end
  end

  @doc false
  def terminate(_reason, [_, port]) do
    send(port, {self(), :close})
  end

  defp get_env_options(module_path, unsecure_tls, nil) do
    [
      {'NODE_PATH', node_path(module_path)},
      {'WRITE_CHUNK_SIZE', String.to_charlist("#{@read_chunk_size}")},
      {'NODE_TLS_REJECT_UNAUTHORIZED', String.to_charlist(unsecure_tls)}
    ]
  end

  defp get_env_options(module_path, unsecure_tls, proxy_settings) do
    [
      {'NODE_PATH', node_path(module_path)},
      {'WRITE_CHUNK_SIZE', String.to_charlist("#{@read_chunk_size}")},
      {'NODE_TLS_REJECT_UNAUTHORIZED', String.to_charlist(unsecure_tls)},
      proxy_settings
    ]
  end
end
