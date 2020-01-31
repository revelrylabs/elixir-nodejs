defmodule NodeJS.Worker do
  use GenServer

  # Port can't do more than this.
  @read_chunk_size 65_536

  @moduledoc """
  A genserver that controls the starting of the node service
  """

  @doc """
  Starts the Supervisor and underlying node service.
  """
  @spec start_link([binary()]) :: {:ok, pid} | {:error, any()}
  def start_link([module_path]) do
    GenServer.start_link(__MODULE__, module_path)
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
    node = System.find_executable("node")

    port =
      Port.open(
        {:spawn_executable, node},
        line: @read_chunk_size,
        env: [
          {'NODE_PATH', node_path(module_path)},
          {'WRITE_CHUNK_SIZE', String.to_charlist("#{@read_chunk_size}")}
        ],
        args: [node_service_path()]
      )

    {:ok, [node_service_path(), port]}
  end

  defp get_response(data \\ '') do
    receive do
      {_, {:data, {flag, chunk}}} ->
        data = data ++ chunk

        case flag do
          :noeol -> get_response(data)
          :eol -> data
        end
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
  def handle_call({module, args, binary}, _from, [_, port] = state) when is_tuple(module) do
    body = Jason.encode!([Tuple.to_list(module), args])
    Port.command(port, "#{body}\n")

    response =
      get_response()
      |> decode_binary(binary)
      |> decode()

    {:reply, response, state}
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

  @doc false
  def terminate(_reason, [_, port]) do
    send(port, {self(), :close})
  end
end
