## [Unreleased]

## [0.1.8] - 2024-04-27

- Add instrumentation for before/after all hooks

## [0.1.7] - 2024-02-07

- Fix retry when connection lost

## [0.1.6] - 2024-02-06

- RSpec test filtering performance optimization
- Fix bug causing test failures on websocket reconnect

## [0.1.5] - 2024-01-26

- Give batches of tests to RSpec. Significantly reduce overhead/improve performance

## [0.1.4] - 2024-01-03

- Upgrade to Ruby 3.3
- Support collection of metadata (framework, version, etc)
- Support option allowing users to disable before/after :all hooks (--require-each-hooks)

## [0.1.3] - 2023-12-08

- Bugfix for zeitwerk when eager loading is enabled

## [0.1.2] - 2023-12-01

- Support before/after all hooks (as before/after each hooks)

## [0.1.1] - 2023-12-01

- Improve support for suite & context hooks
- Fix disabling of profile example groups

## [0.1.0] - 2023-10-26

- Initial release
