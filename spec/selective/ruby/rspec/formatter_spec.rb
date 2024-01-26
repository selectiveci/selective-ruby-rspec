# frozen_string_literal: true

RSpec.describe Selective::Ruby::RSpec::Formatter do
  class TestClass < described_class; end;

  let(:formatter) { TestClass.new(nil) }
  let(:example) { double('example') }
  let(:notification) { double('notification', example: example) }
  let(:callback) { double }

  %i(example_passed example_failed example_pending).each do |method|
    describe "##{method}" do
      before do
        TestClass.callback = callback
        allow(callback).to receive(:call)
        formatter.send(method, notification)
      end

      it 'calls the callback with the notification example' do
        expect(callback).to have_received(:call).with(notification.example)
      end
    end
  end
end