## [Unreleased]

- Run with `--workers N` or `SELECTIVE_WORKERS=N` (selective-ruby-core 0.4.0 or newer). In a Rails app each worker gets its own test database.
- Report whether the command named spec paths narrower than the whole suite, so a parallel_tests or turbo_tests process given a slice is refused instead of offering Selective a partial manifest.
- Exit as `rspec` does when the suite fails to load, with the load errors shown. The runner used to connect anyway and crash with "undefined method `example_group' for nil" once tests were assigned.
- List the suite for the manifest outside any worker's environment, so coverage tools don't count the listing as a worker.

## [0.1.13] - 2026-11-19

- Report the failure detail for `aggregate_failures` examples and for examples whose `after` hook also fails. Both arrived with an empty message and backtrace.
- Add `--preserve-all-hooks`: run `before(:all)`/`after(:all)` as RSpec does, once around each batch's examples of a group, instead of rewriting them into `before(:each)`/`after(:each)`. Use it for suites whose `before(:each)` hooks depend on `let_it_be` or `before_all` state.
- Reset RSpec's per-group example memoization before each batch. A group whose first batch held none of its examples kept that answer and skipped its `before(:all)`/`after(:all)` in later batches.

## [0.1.12] - 2026-11-18

- Allow zeitwerk 2.7 and 2.8. The `~> 2.6.12` pin made Rails apps on current zeitwerk downgrade their autoloader to install Selective.

## [0.1.11] - 2026-10-08

- **Breaking:** require Ruby 2.7 or newer (was 2.6); the CI matrix covers Ruby 2.7 through 4.0.7
- Fix a crash on the second batch of tests with rspec-core 3.8/3.9 (`undefined method 'output'` for the Selective formatter)
- Run the rspec-core 3.8-3.13 matrix on every pull request, plus a non-blocking rspec 4.0.0.beta1 job

## [0.1.10] - 2026-10-03

- Fix a crash at finish when an example failed and then passed on the same runner; the last attempt now replaces earlier ones in the summary and exit status

## [0.1.9] - 2026-09-29

- Trace each example for test maps when the server asks; a pass-through otherwise and with cores older than 0.2.10

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
