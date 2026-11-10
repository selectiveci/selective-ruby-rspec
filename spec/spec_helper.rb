# frozen_string_literal: true

require_relative "helper_methods"
require "selective-ruby-rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Expect syntax only; RSpec 4 has no monkey patching to disable
  config.disable_monkey_patching! if config.respond_to?(:disable_monkey_patching!)

  # Configured here to ensure Selective disables it as it is
  # not compatible.
  config.profile_examples = 10
end
