# NodeJS

[![Build Status](https://travis-ci.org/revelrylabs/elixir_node.svg?branch=master)](https://travis-ci.org/revelrylabs/elixir_node)
[![Hex.pm](https://img.shields.io/hexpm/dt/node.svg)](https://hex.pm/packages/node)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Renders React as HTML

## Documentation

The docs can
be found at [https://hexdocs.pm/node](https://hexdocs.pm/node).

## Installation

```elixir
def deps do
  [
    {:nodejs, "~> 2.0.0"}
  ]
end
```

## Getting Started with Phoenix

- Add `node` to your package.json

```js
"node": "file:../deps/node"
```

- Run `npm install`

```bash
npm install
```

- Create a file named `server.js` in your `assets/js` folder and add the following

```js
const NodeJS = require('node/priv/server')

NodeJS.startServer()
```

- Add `NodeJS` to your Supervisor as a child.

```elixir
supervisor(NodeJS, path: "/my/node/app/root", pool_size: 4)
```

- Call `NodeJS.render/2`

```elixir
  component_path = "./HelloWorld.js"
  props = %{name: "Revelry"}

  NodeJS.render(component_path, props)
```

`component_path` can either be an absolute path or one relative to the render service. The stipulation is that components must be in the same path or a sub directory of the render service. This is so that the babel compiler will be able to compile it. The service will make sure that any changes you make are picked up. It does this by removing the component_path from node's `require` cache. If do not want this to happen, make sure to add `NODE_ENV` to your environment variables with the value `production`.

- To hydrate server-created components in the client, add the following to your `app.js`

```js
import {hydrateClient} from 'node/priv/client'

function getComponentFromStringName(stringName) {
  // Map string component names to your react components here
  if (stringName === 'HelloWorld') {
    return HelloWorld
  }

  return null
}

hydrateClient(getComponentFromStringName)
```
