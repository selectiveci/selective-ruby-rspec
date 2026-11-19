# frozen_string_literal: true

require "selective-ruby-rspec"

file = "./spec/fixtures/context_hooks_cases.rb"
wrapper = Selective::Ruby::RSpec::RunnerWrapper.new(
  ARGV + [file],
  ->(result) { puts "reported: #{result[:id]} #{result[:status]}" }
)
wrapper.run_test_cases(["#{file}[1:1]"])
wrapper.run_test_cases(["#{file}[1:2:1]"])
