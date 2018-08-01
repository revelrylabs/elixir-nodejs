defmodule NodeJS do
  def start_link(opts \\ []), do: NodeJS.Supervisor.start_link(opts)
  def stop(), do: NodeJS.Supervisor.stop()
  def call(module, args \\ []), do: NodeJS.Supervisor.call(module, args)
  def call!(module, args \\ []), do: NodeJS.Supervisor.call!(module, args)
end
