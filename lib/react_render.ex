defmodule ReactRender do
  use Supervisor

  @timeout 5_000
  @pool_name :react_render

  @moduledoc """
  React Renderer
  """

  @doc """
  Starts the ReactRender and workers.

  ## Options
    * `:render_service_path` - (required) is the path to the react render service relative
  to your current working directory
    * `:pool_size` - (optional) the number of workers. Defaults to 4
  """
  @spec start_link(keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(args) do
    default_options = [pool_size: 4]
    opts = Keyword.merge(default_options, args)

    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stops the ReactRender and underlying node react render service
  """
  @spec stop() :: :ok
  def stop() do
    Supervisor.stop(__MODULE__)
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
  @spec render(binary(), map()) :: {:safe, binary()}
  def render(component_path, props \\ %{}) do
    case do_get_html(component_path, props) do
      {:error, %{message: message, stack: stack}} ->
        raise ReactRender.RenderError, message: message, stack: stack

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

        {:safe, html}
    end
  end

  defp do_get_html(component_path, props) do
    task =
      Task.async(fn ->
        :poolboy.transaction(
          @pool_name,
          fn pid -> GenServer.call(pid, {:html, component_path, props}) end,
          @timeout
        )
      end)

    case Task.await(task, 7_000) do
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

  # --- Supervisor Callbacks ---
  @doc false
  def init(opts) do
    pool_size = Keyword.fetch!(opts, :pool_size)
    render_service_path = Keyword.fetch!(opts, :render_service_path)

    pool_opts = [
      name: {:local, @pool_name},
      worker_module: ReactRender.Worker,
      size: pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@pool_name, pool_opts, [render_service_path])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
