# frozen_string_literal: true

require "selective-ruby-rspec"

test_case_id = "./spec/dynamic_definition_spec.rb[1:1]"
wrapper = Selective::Ruby::RSpec::RunnerWrapper.new(
  [test_case_id],
  ->(result) { puts "reported: #{result[:status]}" }
)
2.times { wrapper.run_test_cases([test_case_id]) }
puts "exit_status: #{wrapper.exit_status}"
