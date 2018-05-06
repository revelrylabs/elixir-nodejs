# ServerSideRender

A Plug and GenServer for Server Side Rendering of JavaScript frameworks such as React.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `react_server_render` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:server_side_render, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/react_server_render](https://hexdocs.pm/react_server_render).

## Usage

* Add `ServerSideRender` to your Supervisor as a child

```elixir
  render_server_path = "path/to/server.js"

  worker(ServerSideRender.Server, [render_server_path])
```

**Note** Make sure that your js renderer exits on EOF. Do so by adding the following somewhere in your script

```js
process.stdin.on('end', () => {
  process.exit()
})``
```
