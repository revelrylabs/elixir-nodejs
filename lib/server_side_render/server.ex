defmodule ServerSideRender.Server do
  use GenServer

  @moduledoc """
  A genserver that controls the starting of the node render service
  """

  def start_link(render_server_path, host, port) do
    GenServer.start_link(__MODULE__, [render_server_path, host, port], name: __MODULE__)
  end

  def init([render_server_path, host, port]) do
    System.cmd("node", [render_server_path, port], into: IO.stream(:stdio, :line))
    url = "#{host}:#{port}"
    {:ok, [render_server_path, host, port, url]}
  end

  def get_url() do
    GenServer.call(__MODULE__, :url)
  end

  def handle_call(:url, _from, [_, _, _, url] = state) do
    {:reply, url, state}
  end
end
