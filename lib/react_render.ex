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
    case do_get_html(component_path, props) do
      {:error, _} = error ->
        error

      {:ok, %{"markup" => markup}} ->
        {:ok, markup}
    end
  end

  @doc """
  Same as `get_html/2` but wraps html in a div which is used
  to hydrate react component on client side.

  This is the preferred function when using with Phoenix

  `component_path` is the path to your react component module relative
  to the render service.

  `props` is a map of props given to the component. Must be able to turn into
  json
  """
  @spec render(binary(), map()) :: {:ok, binary()} | {:error, map()}
  def render(component_path, props \\ %{}) do
    case do_get_html(component_path, props) do
      {:error, _} = error ->
        error

      {:ok, %{"markup" => markup, "component" => component}} ->
        props =
          props
          |> Jason.encode!()
          |> String.replace("\"", "&quot;")

        html = """
        <div data-rendered data-component="#{component}" data-props="#{props}">
        #{markup}
        </div>
        """

        {:ok, html}
    end
  end

  defp do_get_html(component_path, props) do
    case GenServer.call(__MODULE__, {:html, component_path, props}) do
      %{"error" => error} when not is_nil(error) ->
        normalized_error = %{
          message: error["message"],
          stack: error["stack"]
        }

        {:error, normalized_error}

      result ->
        {:ok, result}
    end
  end

  # --- GenServer Callbacks ---
  @doc false
  def init([render_server_path]) do
    node = System.find_executable("node")

    port = Port.open({:spawn_executable, node}, args: [render_server_path])

    {:ok, [render_server_path, port]}
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
