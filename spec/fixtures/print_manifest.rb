# frozen_string_literal: true

require "json"
require "selective-ruby-rspec"

wrapper = Selective::Ruby::RSpec::RunnerWrapper.new(ARGV.dup, ->(_) {})
begin
  puts JSON.generate(ids: wrapper.manifest["examples"].map { |e| e["id"] })
rescue Selective::Ruby::RSpec::RunnerWrapper::TestManifestError => e
  puts JSON.generate(error: e.message)
end
