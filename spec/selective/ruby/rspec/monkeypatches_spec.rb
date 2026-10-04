# frozen_string_literal: true

require "open3"

RSpec.describe Selective::Ruby::RSpec::Monkeypatches::Reporter do
  before do
    if Gem::Version.new(::RSpec::Core::Version::STRING) < Gem::Version.new("3.10")
      skip "rspec-core < 3.10 raises on a second run_test_cases in one process: Formatter has no #output"
    end
  end

  def run_twice(outcomes)
    Open3.capture2e(
      {"RERUN_OUTCOMES" => outcomes},
      "bundle", "exec", "ruby", "-Ilib", "spec/fixtures/run_twice.rb",
      chdir: File.expand_path("../../../..", __dir__)
    )
  end

  context "when an example fails and then passes on the same runner" do
    it "should not crash at finish and reports only the passing attempt" do
      output, status = run_twice("fail,pass")

      expect(output.scan(/reported: (\w+)$/).flatten).to eq(%w[failed passed])
      expect(output).not_to include("fully_formatted")
      expect(output).to include("1 example, 0 failures")
      expect(output).to include("exit_status: 0")
      expect(status.exitstatus).to eq(0)
    end
  end

  context "when an example passes and then fails on the same runner" do
    it "reports the failing attempt once" do
      output, status = run_twice("pass,fail")

      expect(output.scan(/reported: (\w+)$/).flatten).to eq(%w[passed failed])
      expect(output).to include("1 example, 1 failure")
      expect(output).to include("exit_status: 1")
      expect(status.exitstatus).to eq(0)
    end
  end
end
