# ReactRender

[![Build Status](https://travis-ci.org/revelrylabs/elixir_react_render.svg?branch=master)](https://travis-ci.org/revelrylabs/elixir_react_render)
[![Hex.pm](https://img.shields.io/hexpm/dt/react_render.svg)](https://hex.pm/packages/react_render)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Renders React as HTML

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `react_server_render` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:react_render, "~> 0.1.0"}
  ]
end
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/react_server_render](https://hexdocs.pm/react_server_render).

## Usage

* Run `mix react_render.install` install the node react render service into your project

```bash
mix react_render.install
```

This installs a folder called `react_render_service` into your priv directory by default.
It contains the react render setup. The command will also ask if you would like to run `npm install`.

* Add `ReactRender` to your Supervisor as a child

```elixir
  render_service_path = "path/to/react_render_service/index.js"

  worker(ReactRender, [render_service_path])
```

* Call `ReactRender.get_html/2`

```elixir
  component_path = "./HelloWorld.js"
  props = %{name: "Revelry"}

  ReactRender.get_html(component_path, props)
```

`component_path` can either be an absolute path or one relative to the render service. The stipulation is that components must be in the same path or a sub directory of the render service. This is so that the babel compiler will be able to compile it. The service will make sure that any changes you make are picked up. It does this by removing the component_path from node's `require` cache. If do not want this to happen, make sure to add `NODE_ENV` to your environment variables with the value `production`.
