defmodule ReactRender.Worker do
  use GenServer

  @moduledoc """
  A genserver that controls the starting of the node render service
  """

  @doc """
  Starts the ReactRender and underlying node react render service.
  """
  @spec start_link([binary()]) :: {:ok, pid} | {:error, any()}
  def start_link([render_service_path]) do
    GenServer.start_link(__MODULE__, render_service_path)
  end

  # --- GenServer Callbacks ---
  @doc false
  def init(render_service_path) do
    node = System.find_executable("node")

    port = Port.open({:spawn_executable, node}, args: [render_service_path])

    {:ok, [render_service_path, port]}
  end

  @doc false
  def handle_call({:html, component_path, props}, _from, [_, port] = state) do
    body =
      Jason.encode!(%{
        path: component_path,
        props: props
      })

    Port.command(port, body <> "\n")

    response =
      receive do
        {_, {:data, data}} ->
          Jason.decode!(to_string(data))
      end

    {:reply, response, state}
  end

  @doc false
  def terminate(_reason, [_, port]) do
    send(port, {self(), :close})
  end
end
