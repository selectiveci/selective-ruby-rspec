# frozen_string_literal: true

require "json"
require "selective-ruby-rspec"

file = "./spec/fixtures/hook_timing_cases.rb"
wrapper = Selective::Ruby::RSpec::RunnerWrapper.new(ARGV - ["--together"] + [file], ->(_) {})
ARGV.include?("--together") ? wrapper.run_test_cases(%w[1 2 3].map { |n| "#{file}[1:#{n}]" }) : %w[1 2 3].each { |n| wrapper.run_test_cases(["#{file}[1:#{n}]"]) }
puts JSON.generate(Selective::Ruby::Core::Controller.report_at_finish)
