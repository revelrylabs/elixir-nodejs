# ReactRender

[![Build Status](https://travis-ci.org/revelrylabs/elixir_react_render.svg?branch=master)](https://travis-ci.org/revelrylabs/elixir_react_render)
[![Hex.pm](https://img.shields.io/hexpm/dt/react_render.svg)](https://hex.pm/packages/react_render)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Renders React as HTML

## Documentation

The docs can
be found at [https://hexdocs.pm/react_render](https://hexdocs.pm/react_render).

## Installation

```elixir
def deps do
  [
    {:react_render, "~> 2.0.0"}
  ]
end
```

## Getting Started with Phoenix

- Add `react_render` to your package.json

```js
"react_render": "file:../deps/react_render"
```

- Run `npm install`

```bash
npm install
```

- Create a file named `server.js` in your `assets/js` folder and add the following

```js
const ReactRender = require('react_render/priv/server')

ReactRender.startServer()
```

- Add `ReactRender` to your Supervisor as a child.

```elixir
  render_service_path = "assets/js/server.js"
  pool_size = 5

  supervisor(ReactRender, [render_service_path: render_service_path, pool_size: 5])
```

- Call `ReactRender.render/2`

```elixir
  component_path = "./HelloWorld.js"
  props = %{name: "Revelry"}

  ReactRender.render(component_path, props)
```

`component_path` can either be an absolute path or one relative to the render service. The stipulation is that components must be in the same path or a sub directory of the render service. This is so that the babel compiler will be able to compile it. The service will make sure that any changes you make are picked up. It does this by removing the component_path from node's `require` cache. If do not want this to happen, make sure to add `NODE_ENV` to your environment variables with the value `production`.

- To hydrate server-created components in the client, add the following to your `app.js`

```js
import {hydrateClient} from 'react_render/priv/client'

function getComponentFromStringName(stringName) {
  // Map string component names to your react components here
  if (stringName === 'HelloWorld') {
    return HelloWorld
  }

  return null
}

hydrateClient(getComponentFromStringName)
```
