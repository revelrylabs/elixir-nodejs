defmodule NodeJS do
  def start_link(opts \\ []), do: NodeJS.Supervisor.start_link(opts)
  def stop(), do: NodeJS.Supervisor.stop()

  @doc """
  Calls a Node.js function. Returns `{:ok, result}` if the call is successful, or `{:error, reason}` if the call fails.

  ## Options
    * `:timeout` (optional): The timeout (in milliseconds) for the call. Defaults to 30 seconds.
    * `:esm` (optional): Whether to use ESM modules. Defaults to false.
    * `:binary` (optional): Whether to return the response in binary form. Defaults to false.

  ## Examples

      > NodeJS.call({"markdown-renderer.js", :renderHTML}, [inputMarkdown], esm: true)
      {:ok, "<html>...</html>"}
  """
  def call(module, args \\ [], opts \\ []), do: NodeJS.Supervisor.call(module, args, opts)

  @doc """
  Calls a Node.js function. Returns the result if the call is successful, or raises `NodeJS.Error`.

  ## Options

  See `call/3` for options.

  ## Example

      > NodeJS.call!({"markdown-renderer.js", :renderHTML}, [inputMarkdown], esm: true)
      "<html>...</html>"
  """
  def call!(module, args \\ [], opts \\ []), do: NodeJS.Supervisor.call!(module, args, opts)
end
