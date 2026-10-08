# frozen_string_literal: true

require "open3"

RSpec.describe Selective::Ruby::RSpec::Formatter do
  class TestClass < described_class; end;

  let(:formatter) { TestClass.new(nil) }
  let(:example) { double('example') }
  let(:notification) { double('notification', example: example) }
  let(:runner_wrapper) { double }

  %i(example_passed example_failed example_pending).each do |method|
    describe "##{method}" do
      before do
        TestClass.runner_wrapper = runner_wrapper
        allow(runner_wrapper).to receive(:report_example)
        formatter.send(method, notification)
      end

      it 'calls the callback with the notification example' do
        expect(runner_wrapper).to have_received(:report_example).with(notification.example)
      end
    end
  end

  context "when a second batch runs in the same process" do
    it "should not crash when rspec-core checks for a duplicate formatter" do
      output, status = Open3.capture2e(
        "bundle", "exec", "ruby", "-Ilib", "spec/fixtures/run_two_batches.rb",
        chdir: File.expand_path("../../../..", __dir__)
      )

      expect(output).not_to include("NoMethodError")
      expect(output.scan(/reported: (\w+)$/).flatten).to eq(%w[passed passed])
      expect(output).to include("exit_status: 0")
      expect(status.exitstatus).to eq(0)
    end
  end
end