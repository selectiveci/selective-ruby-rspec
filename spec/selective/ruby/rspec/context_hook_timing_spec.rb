# frozen_string_literal: true

require "json"
require "open3"

RSpec.describe "context hook timing" do
  before do
    if Gem::Version.new(::RSpec::Core::Version::STRING) < Gem::Version.new("3.10")
      skip "rspec-core < 3.10 raises on a second run_test_cases in one process: Formatter has no #output"
    end
  end

  def report(*args)
    output, status = Open3.capture2e(
      "bundle", "exec", "ruby", "-Ilib", "spec/fixtures/run_hook_timing_batches.rb", *args,
      chdir: File.expand_path("../../../..", __dir__)
    )
    raise output unless status.success?

    JSON.parse(output.lines.last[/\{.*/])
  end

  it "counts a group's setup once per batch and the reruns as their own time" do
    timings = report("--preserve-all-hooks")

    expect(timings).to include("context_hook_groups" => 1, "context_hook_runs" => 3)
    expect(timings["context_hook_ms"]).to be >= 150
    expect(timings["context_hook_rerun_ms"]).to be_between(100, timings["context_hook_ms"] - 50)
  end

  it "reports no reruns when a group's examples share a batch" do
    timings = report("--preserve-all-hooks", "--together")

    expect(timings).to include("context_hook_runs" => 1, "context_hook_rerun_ms" => 0)
  end

  it "reports nothing without --preserve-all-hooks" do
    expect(report.keys.grep(/context_hook/)).to be_empty
  end
end
