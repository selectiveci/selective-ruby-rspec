module Selective
  module Ruby
    module RSpec
      class Formatter
        ::RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending

        def initialize(...); end

        def self.callback=(callback)
          @callback = callback
        end

        def self.callback
          @callback
        end
        
        %i(example_passed example_failed example_pending).each do |method|
          define_method(method) do |notification|
            self.class.callback.call(notification.example)
          end
        end
      end
    end
  end
end