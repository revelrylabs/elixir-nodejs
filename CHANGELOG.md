# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2018-07-26

### Changed

- NodeJS.render/2 now returns `{:safe, html}` so that calls to `raw` in phoenix are no longer needed
- Configuration now takes a keyword list.
  Old:

```elixir
  node_service_path = "assets/js/server.js"
  worker(NodeJS, [node_service_path])
```

New:

```elixir
  node_service_path = "assets/js/server.js"
  supervisor(NodeJS, [node_service_path: node_service_path])
```

### Added

- NodeJS is now a supervisor
- `pool_size` option to control the number of renderers

## [1.0.0] - 2018-06-12

### Added

- NodeJS.get_html/2
- NodeJS.render/2
