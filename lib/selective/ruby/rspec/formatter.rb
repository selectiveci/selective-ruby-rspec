module Selective
  module Ruby
    module RSpec
      class Formatter
        ::RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending

        def initialize(...); end

        def self.runner_wrapper=(runner_wrapper)
          @runner_wrapper = runner_wrapper
        end

        def self.runner_wrapper
          @runner_wrapper
        end
        
        %i(example_passed example_failed example_pending).each do |method|
          define_method(method) do |notification|
            self.class.runner_wrapper.report_example(notification.example)
          rescue Selective::Ruby::Core::ConnectionLostError
            ::RSpec.world.wants_to_quit = true
            self.class.runner_wrapper.connection_lost = true
            self.class.runner_wrapper.remove_test_case_result(notification.example.id)
          end
        end
      end
    end
  end
end