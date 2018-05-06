defmodule ReactRender do
  use GenServer

  @moduledoc """
  A genserver that controls the starting of the node render service
  """

  @doc """
  Starts the ReactRender and underlying node react render service
  `render_server_path` is the path to the react render service relative
  to your current working directory
  """
  @spec start_link(binary()) :: {:ok, pid} | {:error, any()}
  def start_link(render_server_path) do
    GenServer.start_link(__MODULE__, [render_server_path], name: __MODULE__)
  end

  @doc """
  Stops the ReactRender and underlying node react render service
  """
  @spec stop() :: :ok
  def stop() do
    GenServer.stop(__MODULE__)
  end

  @doc """
  Given the `component_path` and `props`, returns html.

  `component_path` is the path to your react component module relative
  to the render service.

  `props` is a map of props given to the component. Must be able to turn into
  json
  """
  @spec get_html(binary(), map()) :: {:ok, binary()} | {:error, map()}
  def get_html(component_path, props \\ %{}) do
    case GenServer.call(__MODULE__, {:html, component_path, props}) do
      %{"error" => error} when not is_nil(error) ->
        normalized_error = %{
          message: error["message"],
          stack: error["stack"]
        }

        {:error, normalized_error}

      %{"markup" => html} ->
        {:ok, html}
    end
  end

  # --- GenServer Callbacks ---

  def init([render_server_path]) do
    node = System.find_executable("node")

    port = Port.open({:spawn_executable, node}, args: [render_server_path])

    {:ok, [render_server_path, port]}
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
