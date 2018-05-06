defmodule ServerSideRender do
  use GenServer

  @moduledoc """
  A genserver that controls the starting of the node render service
  """

  def start_link(render_server_path) do
    GenServer.start_link(__MODULE__, [render_server_path], name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def init([render_server_path]) do
    node = System.find_executable("node")

    port = Port.open({:spawn_executable, node}, args: [render_server_path])

    {:ok, [render_server_path, port]}
  end

  def get_html(component_path, props \\ %{}) do
    GenServer.call(__MODULE__, {:html, component_path, props})
  end

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

  def terminate(_reason, [_, port]) do
    send(port, {self(), :close})
  end
end
