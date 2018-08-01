defmodule NodeJS.Supervisor do
  use Supervisor

  @timeout 10_000
  @pool_name :nodejs
  @default_pool_size 4

  @moduledoc """
  React Renderer
  """

  @doc """
  Starts the NodeJS and workers.

  ## Options
    * `:pool_size` - (optional) the number of workers. Defaults to 4
  """
  @spec start_link(binary(), keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(modules_path, opts \\ []) do
    opts = Keyword.put(opts, :modules_path, modules_path)
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stops the Supervisor and underlying node service
  """
  @spec stop() :: :ok
  def stop() do
    Supervisor.stop(__MODULE__)
  end

  defp to_transaction(module, args) do
    fn ->
      :poolboy.transaction(
        @pool_name,
        fn pid -> GenServer.call(pid, {module, args}) end,
        :infinity
      )
    end
  end

  def call(module, args \\ [])

  def call(module, args) when is_bitstring(module), do: call({module}, args)

  def call(module, args) when is_tuple(module) and is_list(args) do
    module
    |> to_transaction(args)
    |> Task.async()
    |> Task.await(@timeout)
  end

  def call!(module, args \\ []) do
    module
    |> call(args)
    |> case do
      {:ok, result} -> result
      {:error, message} -> raise NodeJS.Error, message: message
    end
  end

  defp node_service_path() do
    Path.join(:code.priv_dir(:nodejs), "server.js")
  end

  # --- Supervisor Callbacks ---
  @doc false
  def init(opts) do
    modules_path = Keyword.fetch!(opts, :modules_path)
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)

    pool_opts = [
      name: {:local, @pool_name},
      worker_module: NodeJS.Worker,
      size: pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@pool_name, pool_opts, [node_service_path(), modules_path])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
