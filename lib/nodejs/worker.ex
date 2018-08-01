defmodule NodeJS.Worker do
  use GenServer

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

  defp node_service_path() do
    Path.join(:code.priv_dir(:nodejs), "server.js")
  end

  # --- GenServer Callbacks ---
  @doc false
  def init(module_path) do
    node = System.find_executable("node")
    port = Port.open({:spawn_executable, node}, env: [{'NODE_PATH', String.to_charlist(module_path)}], args: [node_service_path()])
    {:ok, [node_service_path(), port]}
  end

  @doc false
  def handle_call({module, args}, _from, [_, port] = state) when is_tuple(module) do
    body = Jason.encode!([Tuple.to_list(module), args])
    Port.command(port, "#{body}\n")
    response = receive do {_, {:data, data}} -> decode(data) end
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
