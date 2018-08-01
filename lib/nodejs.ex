defmodule NodeJS do
  def start_link(module_path, opts \\ []), do: NodeJS.Supervisor.start_link(module_path, opts)
  def stop(), do: NodeJS.Supervisor.stop()
  def call(module, args \\ []), do: NodeJS.Supervisor.call(module, args)
  def call!(module, args \\ []), do: NodeJS.Supervisor.call!(module, args)
end
