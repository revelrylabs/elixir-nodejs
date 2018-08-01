defmodule NodeJS.Supervisor do
  use Supervisor

  @timeout 10_000
  @pool_name :nodejs
  @default_pool_size 4

  @moduledoc """
  NodeJS.Supervisor
  """

  @doc """
  Starts the Node.js supervisor and workers.

  ## Options
    * `:path` - (required) The path to your Node.js code's root directory.
    * `:pool_size` - (optional) The number of workers. Defaults to #{@default_pool_size}.
  """
  @spec start_link(keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(opts \\ []) do
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

  # --- Supervisor Callbacks ---
  @doc false
  def init(opts) do
    path = Keyword.fetch!(opts, :path)
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)

    pool_opts = [
      name: {:local, @pool_name},
      worker_module: NodeJS.Worker,
      size: pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@pool_name, pool_opts, [path])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
