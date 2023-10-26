# frozen_string_literal: true

require_relative "helper_methods"
require "selective-ruby-rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configured here to ensure Selective disables it as it is
  # not compatible.
  config.profile_examples = 10
end
