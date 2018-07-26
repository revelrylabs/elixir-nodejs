# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [2.0.0-dev]

### Changed

- ReactRender.render/2 now returns `{:safe, html}` so that calls to `raw` in phoenix are no longer needed
- Configuration now takes a keyword list.
  Old:

```elixir
  render_service_path = "assets/js/server.js"
  worker(ReactRender, [render_service_path])
```

New:

```elixir
  render_service_path = "assets/js/server.js"
  supervisor(ReactRender, [render_service_path: render_service_path])
```

### Added

- ReactRender is now a supervisor
- `pool_size` option to control the number of renderers

## [1.0.0] - 2018-06-12

### Added

- ReactRender.get_html/2
- ReactRender.render/2
