# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [3.0.0]

### Changed
- update language support minimums to Elixir 1.12, OTP 24, and Node 18
- format code with the latest `mix format` settings
- replace Travis CI with GitHub Actions for CI/CD
- add `.dependabot.yml` config file
- remove coverage reporting
- upgrade dependencies

### Fixed
- fixed test error due to JS TypeError format change

### Contributors
- @quentin-bettoum


## [2.0.0]

### Added
- support for GenServer name registration to support multiple supervisors

### Changed
- updated Elixir requirements to 1.7

### Fixed
- `Task.async` and `Task.await` caller leaks with timeouts and worker crash
- `console.*` calls in JavaScript code no longer causes workers to crash
