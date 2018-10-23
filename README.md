# NodeJS

[![Build Status](https://travis-ci.org/revelrylabs/elixir-nodejs.svg?branch=master)](https://travis-ci.org/revelrylabs/elixir-nodejs)
[![Hex.pm](https://img.shields.io/hexpm/dt/nodejs.svg)](https://hex.pm/packages/nodejs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage Status](https://coveralls.io/repos/github/revelrylabs/elixir-nodejs/badge.svg?branch=master)](https://coveralls.io/github/revelrylabs/elixir-nodejs?branch=master)

Provides an Elixir API for calling Node.js functions.

## Documentation

The docs can
be found at [https://hexdocs.pm/nodejs](https://hexdocs.pm/nodejs).

## Prerequisites

* Elixir >= 1.6
* NodeJS >= 10

## Installation

```elixir
def deps do
  [
    {:nodejs, "~> 0.1.0"}
  ]
end
```

## Starting the service

Add `NodeJS` to your Supervisor as a child, pointing the required `path` option at the
directory containing your JavaScript modules.

```elixir
supervisor(NodeJS, [[path: "/node_app_root", pool_size: 4]])
```

### Calling JavaScript module functions with `NodeJS.call(module, args \\ [])`.

If the module exports a function directly, like this:

```javascript
module.exports = (x) => x
```

You can call it like this:

```elixir
NodeJS.call("echo", ["hello"]) #=> {:ok, "hello"}
```

There is also a `call!` form that throws on error instead of returning a tuple:

```elixir
NodeJS.call!("echo", ["hello"]) #=> "hello"
```

If the module exports an object with named functions like:

```javascript
exports.add = (a, b) => a + b
exports.sub = (a, b) => a - b
```

You can call them like this:

```elixir
NodeJS.call({"math", :add}, [1, 2]) # => {:ok, 3}
NodeJS.call({"math", :sub}, [1, 2]) # => {:ok, -1}
```

### There Are Rules & Limitations (Unfortunately)

* Function arguments must be serializable to JSON.
* Return values must be serializable to JSON. (Objects with circular references will definitely fail.)
* Modules must be requested relative to the `path` that was given to the `Supervisor`.
  E.g., for a `path` of `/node_app_root` and a file `/node_app_root/foo/index.js` your module request should be for `"foo/index.js"` or `"foo/index"` or `"foo"`.
* To reference `node_modules` dependecies, do one of the following:
  * Make local modules that re-export the functions you want.
  * Request the module as `"node_modules/<name>"`. (Not `"<name>"` as you would in Node.)
