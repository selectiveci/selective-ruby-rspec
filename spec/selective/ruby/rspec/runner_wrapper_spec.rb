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
    allow(Selective::Ruby::RSpec::Formatter).to receive(:callback=)
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
      expect(Selective::Ruby::RSpec::Formatter).to have_received(:callback=).with(Method)
    end
  end

  describe "#manifest" do
    it "generates a manifest" do
      result = runner_wrapper.manifest
      expect(result.keys).to eq(["version", "examples", "summary", "summary_line"])
      expect(result["examples"].length).to be > 0
    end

    context "when no examples are found" do
      let(:args) { ["spec/spec_helper.rb"] }

      it "raises a test manifest error" do
        expect { runner_wrapper.manifest }.to raise_error(Selective::Ruby::RSpec::RunnerWrapper::TestManifestError, /No examples found/)
      end
    end

    context "when JSON cannot parse the manifest" do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "raises a test manifest error" do
        expect { runner_wrapper.manifest }.to raise_error(Selective::Ruby::RSpec::RunnerWrapper::TestManifestError, /JSON::ParserError/)
      end
    end

    context "when something else goes wrong" do
      let(:args) { ["path/that/does/not/exist.rb"] }

      it "raises a test manifest error" do
        expect { runner_wrapper.manifest }.to raise_error(Selective::Ruby::RSpec::RunnerWrapper::TestManifestError, /cannot load such file/)
      end
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

  describe "#remove_failed_test_case_result" do
    it "removes failed test cases" do
      ::RSpec.world.reporter.failed_examples << meta_example
      ::RSpec.world.reporter.examples << meta_example
      runner_wrapper.remove_failed_test_case_result(meta_example.id)
    end
  end

  describe "#failure_formatter" do
    it "returns a hash with the expected keys" do
      meta_example.execution_result.exception = StandardError.new("error")
      expect(runner_wrapper.failure_formatter(meta_example).keys).to include(:failure_message_lines, :failure_formatted_backtrace)
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
