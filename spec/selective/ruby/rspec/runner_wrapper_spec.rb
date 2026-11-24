# frozen_string_literal: true

RSpec.describe Selective::Ruby::RSpec::RunnerWrapper do
  let(:runner_wrapper) { dirty_dirty_unprivate_class(described_class).new(args, example_callback) }
  let(:example_callback) { ->(example) {} }
  let(:rspec_runner) { instance_double(::RSpec::Core::Runner, setup: nil) }
  let(:args) { [] }

  let(:meta_example) do
    ::RSpec::Core::Example.new(self.class.superclass, "testing 123", {})
  end

  before do
    allow(Selective::Ruby::RSpec::Monkeypatches).to receive(:apply)
    allow(Selective::Ruby::RSpec::Formatter).to receive(:runner_wrapper=)
    allow(::RSpec).to receive(:configure)
    allow(::RSpec::Core::Runner).to receive(:new).and_return(rspec_runner)
    allow(runner_wrapper).to receive(:apply_formatter)
  end

  describe '.initialize' do
    before { runner_wrapper }
    
    it 'applies monkeypatches' do
      expect(Selective::Ruby::RSpec::Monkeypatches).to have_received(:apply)
    end

    it 'sets the example_callback' do
      expect(runner_wrapper.example_callback).to eq(example_callback)
    end

    it 'sets the formatter callback' do
      expect(Selective::Ruby::RSpec::Formatter).to have_received(:runner_wrapper=).with(runner_wrapper)
    end
  end

  describe "#exec" do
    before do
      allow(rspec_runner).to receive(:run)
    end

    it "calls run on the rspec_runner" do
      runner_wrapper.exec
      expect(rspec_runner).to have_received(:run).with($stderr, $stdout)
    end
  end

  describe "#remove_test_case_result" do
    it "removes failed test cases" do
      ::RSpec.world.reporter.failed_examples << meta_example
      ::RSpec.world.reporter.examples << meta_example
      runner_wrapper.remove_test_case_result(meta_example.id)
    end
  end

  describe "#failure_formatter" do
    it "returns a hash with the expected keys" do
      meta_example.execution_result.exception = StandardError.new("error")
      expect(runner_wrapper.failure_formatter(meta_example).keys).to include(:failure_message_lines, :failure_formatted_backtrace)
    end

    it "reports every failure from aggregate_failures" do
      begin
        aggregate_failures do
          expect(1).to eq(2)
          expect(3).to eq(4)
        end
      rescue RSpec::Expectations::MultipleExpectationsNotMetError => error
        meta_example.execution_result.exception = error
      end

      lines = runner_wrapper.failure_formatter(meta_example)[:failure_message_lines]
      expect(lines.first).to start_with("Got 2 failures")
      expect(lines.join("\n")).to include("expected: 2", "expected: 4")
      expect(lines).not_to include(meta_example.full_description)
    end

    it "reports both an example failure and a hook error" do
      example_error = StandardError.new("example failed").tap { |e| e.set_backtrace(["spec/a_spec.rb:1"]) }
      hook_error = RuntimeError.new("after hook boom").tap { |e| e.set_backtrace(["spec/a_spec.rb:2"]) }
      meta_example.execution_result.exception = RSpec::Core::MultipleExceptionError.new(example_error, hook_error)

      text = runner_wrapper.failure_formatter(meta_example)[:failure_message_lines].join("\n")
      expect(text).to include("example failed", "after hook boom")
    end
  end

  describe '#framework' do
    it 'returns the expected value' do
      expect(runner_wrapper.framework).to eq('rspec')
    end
  end

  describe '#framework_version' do
    it 'returns the current rspec core version' do
      expect(runner_wrapper.framework_version).to eq(::RSpec::Core::Version::STRING)
    end
  end

  describe '#wrapper_version' do
    it 'returns gem version' do
      expect(runner_wrapper.wrapper_version).to eq(Selective::Ruby::RSpec::VERSION)
    end
  end
end
