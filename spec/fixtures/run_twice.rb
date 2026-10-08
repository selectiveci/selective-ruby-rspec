# frozen_string_literal: true

require "selective-ruby-rspec"

test_case_id = "./spec/fixtures/rerun_example.rb[1:1]"
wrapper = Selective::Ruby::RSpec::RunnerWrapper.new(
  [test_case_id],
  ->(result) { puts "reported: #{result[:status]}" }
)
2.times { wrapper.run_test_cases([test_case_id]) }
Selective::Ruby::Core::Controller.restore_reporting!
wrapper.finish
puts "exit_status: #{wrapper.exit_status}"
