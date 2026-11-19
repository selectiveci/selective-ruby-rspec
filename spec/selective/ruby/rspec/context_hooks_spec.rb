# frozen_string_literal: true

require "open3"

RSpec.describe "before(:all) hooks across batches" do
  before do
    if Gem::Version.new(::RSpec::Core::Version::STRING) < Gem::Version.new("3.10")
      skip "rspec-core < 3.10 raises on a second run_test_cases in one process: Formatter has no #output"
    end
  end

  def run_batches(*wrapper_args)
    output, _status = Open3.capture2e(
      "bundle", "exec", "ruby", "-Ilib", "spec/fixtures/run_context_hooks_batches.rb", *wrapper_args,
      chdir: File.expand_path("../../../..", __dir__)
    )
    output.scan(/reported: (\S+) (\w+)$/).to_h
  end

  it "runs a nested group's setup when its examples arrive in a later batch" do
    expect(run_batches).to eq(
      "./spec/fixtures/context_hooks_cases.rb[1:1]" => "passed",
      "./spec/fixtures/context_hooks_cases.rb[1:2:1]" => "passed"
    )
  end

  it "runs before(:all) natively, ahead of before(:each), with --preserve-all-hooks" do
    expect(run_batches("--preserve-all-hooks")).to eq(
      "./spec/fixtures/context_hooks_cases.rb[1:1]" => "passed",
      "./spec/fixtures/context_hooks_cases.rb[1:2:1]" => "passed"
    )
  end
end
