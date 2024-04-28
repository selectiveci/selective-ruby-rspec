require 'benchmark'

module Selective
  module Ruby
    module RSpec
      module Monkeypatches
        MAP = {
          "BaseTextFormatter" => [:message, :dump_pending, :seed, :close],
          "ProgressFormatter" => [:start_dump],
          "DocumentationFormatter" => [:message],
          "ProfileFormatter" => [:dump_profile]
        }

        MAP.each do |module_name, methods|
          m = Selective::Ruby::RSpec::Monkeypatches.const_set(module_name, Module.new)
          methods.each do |method|
            m.define_method(method) do |*args|
            end
          end
        end

        module Reporter
          def finish
            return if Selective::Ruby::Core::Controller.suppress_reporting?
            # This handles the scenario of no tests to run
            start(nil) if @start.nil?
            if ::RSpec.configuration.profile_examples
              puts "\n\nExample group profiling is not supported with Selective and is now disabled.\n\n"
              ::RSpec.configuration.profile_examples = nil
            end

            super
          end

          def start(*args)
            return if Selective::Ruby::Core::Controller.suppress_reporting?

            super
          end

          def register_listener(listener, *notifications)
            # Prevent double registration of listeners with
            # the same output path.
            filtered_notifications = notifications.reject do |n|
              @listeners[n.to_sym].any? do |l|
                next false unless [l, listener].all? do |x|
                  x.respond_to?(:output) && x.output.respond_to?(:path)
                end

                # :nocov:
                l.output.path == listener.output.path
                # :nocov:
              end
            end

            super(listener, *filtered_notifications)
          end
        end

        module Configuration
          attr_accessor :currently_loading_spec_file

          def load_file_handling_errors(method, file)
            self.currently_loading_spec_file = file
            super
          ensure
            self.currently_loading_spec_file = nil
          end

          def get_files_to_run(*args)
            super.reject { |f| loaded_spec_files.member?(f) }
          end

          def with_suite_hooks
            return yield if dry_run?

            unless @before_suite_hooks_run
              ::RSpec.current_scope = :before_suite_hook
              run_suite_hooks("a `before(:suite)` hook", @before_suite_hooks)
              @before_suite_hooks_run = true
            end

            yield
          end

          def after_suite_hooks
            return if dry_run?

            ::RSpec.current_scope = :after_suite_hook
            run_suite_hooks("an `after(:suite)` hook", @after_suite_hooks)
            ::RSpec.current_scope = :suite
          end
        end

        module World
          attr_accessor :example_map

          def initialize(*args)
            super
            @example_map = {}
          end

          def prepare_example_filtering
            @filtered_examples = Hash.new do |hash, group|
              hash[group] = if ::RSpec.configuration.dry_run?
                filter_manager.prune(group.examples)
              else
                []
              end
            end
          end
        end

        module Runner
          attr_writer :options
        end

        module Example
          def initialize(*args)
            super
            ::RSpec.world.example_map[id] = self
          end

          def run(*args)
            @exception = nil
            super
          end
        end

        module MetaHashPopulator
          def populate_location_attributes
            user_metadata[:caller] ||= caller unless ::RSpec.configuration.currently_loading_spec_file.nil?
            super
          end

          def file_path_and_line_number_from(backtrace)
            return super if ::RSpec.configuration.currently_loading_spec_file.nil?

            filtered = backtrace.find { |l| l.include? ::RSpec.configuration.currently_loading_spec_file }
            filtered.nil? ? super : super([filtered])
          end
        end

        module RSpec
          unless ::RSpec.respond_to?(:current_scope)
            def current_scope=(scope)
              # No-op! Older versions of RSpec don't have this method.
              # so we're adding it here if it's not defined since our
              # monkeypatching references it.
            end
          end
        end


        HOOKS = %i(before prepend_before after append_after)
        module Hooks
          HOOKS.each do |hook|
            define_method(hook) do |*args, &block|
              if args.any? { |a| a == :all}
                args = args.map { |a| a == :all ? :each : a }
                super(*args, &->(example) {
                  Benchmark.measure { example.instance_exec(example, &block) }.tap do |time|
                    Selective::Ruby::Core::Controller.report_at_finish.tap do |report_at_finish|
                      key = :"seconds_in_#{hook}_all_hooks"
                      report_at_finish[key] ||= 0
                      report_at_finish[key] += time.real
                    end
                  end
                })
              else
                super(*args, &block)
              end
            end
          end
        end

        module RequireEachHooks
          HOOKS.each do |hook|
            define_method(hook) do |*args, &block|
              if args.none? { |a| a == :all}
                super(*args, &block)
              else
                super(*args) do
                  raise "Before :all hooks are not supported when using --require-each-hooks. Please use before(:each) instead."
                end
              end
            end
          end
        end

        def self.apply(config)
          ::RSpec::Support.require_rspec_core("formatters/base_text_formatter")

          MAP.each do |module_name, _methods|
            ::RSpec::Core::Formatters
              .const_get(module_name)
              .prepend(Selective::Ruby::RSpec::Monkeypatches.const_get(module_name))
          end

          # We'd like to prepend to ::RSpec::Core::Hooks here but there is
          # a bug in < Ruby 3.0 that prevents us from doing so. Instead,
          # we extend the ExampleGroup class which is where the Hooks module
          # is included.
          if config[:require_each_hooks]
            ::RSpec::Core::ExampleGroup.extend(RequireEachHooks)
          else
            ::RSpec::Core::ExampleGroup.extend(Hooks)
          end

          ::RSpec.singleton_class.prepend(RSpec)
          ::RSpec::Core::Reporter.prepend(Reporter)
          ::RSpec::Core::Configuration.prepend(Configuration)
          ::RSpec::Core::World.prepend(World)
          ::RSpec::Core::Runner.prepend(Runner)
          ::RSpec::Core::Example.prepend(Example)
          ::RSpec::Core::Metadata::HashPopulator.prepend(MetaHashPopulator)
        end
      end
    end
  end
end
