# frozen_string_literal: true

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
end