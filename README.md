# Selective RSpec Runner

Selective is an intelligent test runner built to run in your current CI with a goal of shortening the feedback cycle to the first failure. It does queue-based test splitting using prioritized tests from code changes and time.

## Basic Setup

Our goal for Selective is to make it as easy as possible to setup in your CI environment with minimal changes to your workflows/pipelines.

We have created an Action for GitHub Actions and an Orb for CircleCI to assist with setup. All other CI providers will [require additional setup](#other-ci-providers).

## Setup Steps

1. Install the gem for your testing framework: `bundle add selective-ruby-rspec`

   > 💡 In case of an error Unable to find executable for <platform>. Check your `Gemfile.lock` to see if the platform is listed in `PLATFORMS` sections. If not, run `bundle lock --add-platform <platform>`.
   > Currently support platforms:
   >
   > - arm64-darwin
   > - x86_64-darwin
   > - x86_64-linux
   > - aarch64-linux

2. Add your Selective API Key to your CI provider’s secrets
3. Configure Selective in your CI Pipeline. [See below for examples.](#github-actions)
4. Change the rspec command in your CI pipeline from `bundle exec rspec` to `bundle exec selective rspec`. All rspec CLI flags are supported.

### Github Actions

[View a full/working example](https://github.com/selectiveci/selective-ruby-rspec/blob/main/.github/workflows/main.yml)

```yaml
# GitHub Actions Example
- name: Setup Selective
    uses: selectiveci/setup-selective@v1
    with:
      api-key: ${{ secrets.SELECTIVE_API_KEY }}
      runner-id: ${{ matrix.ci_node_index }}
```

### CircleCI

[View a full/working example](https://github.com/selectiveci/selective-ruby-rspec/blob/main/.circleci/config.yml)

```yaml
# CircleCI Orb Example
- setup-selective/init:
    actor: << pipeline.trigger_parameters.github_app.user_username >>
    run_id: << pipeline.id >>
    target_branch: main
```

### Other CI Providers

Selective supports all CI providers. If your provider is not in the list above, set the following environment variables:

| Environment Variable    | Required? | Description                                                                                                              |
| ----------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------ |
| SELECTIVE_API_KEY       | Yes       | The API Key provided when creating a suite in Selective.                                                                 |
| SELECTIVE_PLATFORM      | Yes       | The CI Platform that the Selective client is running on. Example: mint, semaphore, etc.                                  |
| SELECTIVE_RUN_ID        | Yes       | A unique id for each run of the test suite that stays consistent between reruns but changes when new commits are pushed. |
| SELECTIVE_RUN_ATTEMPT   | Yes       | A unique value for each rerun of a particular run/commit started from the CI provider.                                   |
| SELECTIVE_RUNNER_ID     | Yes       | A unique id for each runner in CI that stays consistent between runs and reruns. Example: the index of the runner.       |
| SELECTIVE_BRANCH        | Yes       | Working branch for the commit                                                                                            |
| SELECTIVE_SHA           | Yes       | Commit SHA                                                                                                               |
| SELECTIVE_TARGET_BRANCH | No        | The target branch for a Pull Request or the default branch e.g. main                                                     |
| SELECTIVE_PR_TITLE      | No        | The PR Title from GitHub if available at CI provider                                                                     |
| SELECTIVE_ACTOR         | No        | The GitHub user/committer                                                                                                |

### Need help?

Please don’t hesitate to shoot us an email at support@selective.ci. We’re eager to help.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/selectiveci/selective-ruby-rspec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/selectiveci/selective-ruby-rspec/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
