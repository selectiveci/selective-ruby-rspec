# Selective RSpec Runner

Selective is an intelligent test runner that shortens the feedback cycle on CI. Tests are evenly distributed across parallel runners by a queue-based system. When available, the PR changeset is used to intelligently order tests such that those likely to fail are run first. Results are streamed to a Dashboard where the combined results from all parallel runners/nodes can be viewed in real time.

Selective is currently in Alpha. If you'd like to try it out, please email alpha@selecive.ci.

## Basic Setup

Selective is easy to set up in your CI environment and requires minimal configuration changes.

While we support all CI providers, there are several listed below that have first-class support. We're adding more providers to the list as we go. Please [let us know](#need-help) what providers you'd like to see next.

If your CI provider is not listed, you can [set the required environment variables](#other-ci-providers) manually.

## Setup Steps

1. Install the gem for your testing framework: `bundle add selective-ruby-rspec`

   > 💡 In case of an error Unable to find executable for \<platform\>. Check your `Gemfile.lock` to see if the platform is listed in `PLATFORMS` sections. If not, run `bundle lock --add-platform <platform>`.
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

### Mint

[View a full/working example](https://github.com/selectiveci/selective-ruby-rspec/blob/main/.mint/push.yml)

[Create a secret](https://www.rwx.com/docs/mint/secrets) with your API key (`SELECTIVE_API_KEY`). Mint does not require any additional setup.

### CircleCI

[View a full/working example](https://github.com/selectiveci/selective-ruby-rspec/blob/main/.circleci/config.yml)

Ensure you have set an environment variable with your API key (`SELECTIVE_API_KEY`) in your [project](https://circleci.com/docs/set-environment-variable/#set-an-environment-variable-in-a-project) or [context](https://circleci.com/docs/set-environment-variable/#set-an-environment-variable-in-a-context).

```yaml
# CircleCI Orb Example
- setup-selective/init:
    actor: << pipeline.trigger_parameters.github_app.user_username >>
    run_id: << pipeline.id >>
    target_branch: main
```

### Semaphore

[View a full/working example](https://github.com/selectiveci/selective-ruby-rspec/blob/main/.semaphore/semaphore.yml)

[Create a secret](https://docs.semaphoreci.com/essentials/using-secrets/) with your API key (`SELECTIVE_API_KEY`). Semaphore does not require any additional setup.

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
