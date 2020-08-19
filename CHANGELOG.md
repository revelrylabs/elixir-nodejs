# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [2.0.0]

### Added
- support for GenServer name registration to support multiple supervisors

### Fixed
- `Task.async` and `Task.await` caller leaks with timeouts and worker crash
- `console.*` calls in JavaScript code no longer causes workers to crash
