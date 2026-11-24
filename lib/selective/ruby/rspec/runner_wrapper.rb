module Selective
  module Ruby
    module RSpec
      class RunnerWrapper
        class TestManifestError < StandardError; end

        attr_reader :rspec_runner, :config, :example_callback
        attr_accessor :connection_lost

        FRAMEWORK = "rspec"
        DEFAULT_SPEC_PATH = "./spec"

        def initialize(args, example_callback)
          @example_callback = example_callback
          rspec_args, wrapper_config_hash = parse_args(args)
          @preserve_all_hooks = wrapper_config_hash[:preserve_all_hooks] == true
          Selective::Ruby::RSpec::Monkeypatches.apply(wrapper_config_hash)
          apply_rspec_configuration

          @config = ::RSpec::Core::ConfigurationOptions.new(rspec_args)
          if config.options[:files_or_directories_to_run].empty?
            config.options[:files_or_directories_to_run] = [DEFAULT_SPEC_PATH]
          end

          Formatter.runner_wrapper = self

          @rspec_runner = ::RSpec::Core::Runner.new(@config)
          @rspec_runner.setup($stderr, $stdout)
        end

        def manifest
          captured = ::RSpec.world.selective_manifest || Manifest.capture(::RSpec.world)
          raise_test_manifest_error(captured.load_errors.join("\n")) if captured.failed_to_load?
          raise_test_manifest_error("No examples found") if captured.examples.empty?

          {"examples" => captured.examples}
        end

        def run_test_cases(test_case_ids)
          ensure_test_phase
          configure(test_case_ids)
          groups = optimize_test_filtering(test_case_ids).to_a
          reset_group_memoization(groups)
          rspec_runner.run_specs(groups)
          Selective::Ruby::Core::Controller.report_at_finish.merge!(ContextHookTiming.report) if @preserve_all_hooks
          if connection_lost
            self.connection_lost = false
            raise Selective::Ruby::Core::ConnectionLostError
          end
        end

        def exec
          rspec_runner.run($stderr, $stdout)
        end

        def remove_test_case_result(test_case_id)
          failure = ::RSpec.world.reporter.failed_examples.detect { |e| e.id == test_case_id }
          if (failed_example_index = ::RSpec.world.reporter.failed_examples.index(failure))
            ::RSpec.world.reporter.failed_examples.delete_at(failed_example_index)
          end
          example = get_example_from_reporter(test_case_id)
          ::RSpec.world.reporter.examples.delete_at(::RSpec.world.reporter.examples.index(example))
        end

        def base_test_path
          file = config.options[:files_or_directories_to_run].first
          Pathname(normalize_path(file)).each_filename.first
        end

        def exit_status
          if Gem::Version.new(::RSpec::Core::Version::STRING) >= Gem::Version.new("3.10")
            rspec_runner.exit_code(::RSpec.world.reporter.failed_examples.none?)
          else
            return ::RSpec.world.reporter.exit_early(rspec_runner.configuration.failure_exit_code) if ::RSpec.world.wants_to_quit

            ::RSpec.world.reporter.failed_examples.any? ? 1 : 0
          end
        end

        def finish
          rspec_runner.configuration.after_suite_hooks
          ::RSpec.world.reporter.finish
        end

        def framework
          RunnerWrapper::FRAMEWORK
        end

        def framework_version
          ::RSpec::Core::Version::STRING
        end

        def wrapper_version
          RSpec::VERSION
        end

        def report_example(example)
          example_callback.call(format_example(example))
        end

        private

        def parse_args(args)
          supported_wrapper_args = %w[--require-each-hooks --preserve-all-hooks]
          wrapper_args, rspec_args = args.partition do |arg|
            supported_wrapper_args.any? do |p|
              arg.start_with?(p)
            end
          end

          wrapper_config_hash = wrapper_args.each_with_object({}) do |arg, hash|
            key = arg.sub('--', '').tr('-', '_').to_sym
            hash[key] = true
          end

          rspec_args << "--format=progress" unless args.any? { |e| e.start_with?("--format") }
          [rspec_args, wrapper_config_hash]
        end

        def get_example_from_reporter(test_case_id)
          ::RSpec.world.reporter.examples.detect { |e| e.id == test_case_id }
        end

        def normalize_path(path)
          Pathname.new(path).relative_path_from("./")
        end

        def format_example(example)
          {
            id: example.id,
            description: example.description,
            full_description: example.full_description,
            status: example.execution_result.status.to_s,
            file_path: example.metadata[:file_path],
            line_number: example.metadata[:line_number],
            run_time: example.execution_result.run_time,
            pending_message: example.execution_result.pending_message
          }.tap { |h| h.merge!(failure_formatter(example)) if h[:status] == "failed" }
        end

        def failure_formatter(example)
          presenter = ::RSpec::Core::Formatters::ExceptionPresenter::Factory.new(example).build
          message_lines = presenter.message_lines
          message_lines = multiple_exception_lines(presenter) if message_lines.empty?

          {
            failure_message_lines: message_lines,
            failure_formatted_backtrace: presenter.formatted_backtrace
            # failure_full_backtrace: example.exception.backtrace
          }
        end

        # RSpec keeps the detail of a MultipleExceptionError (aggregate_failures,
        # or an example and a hook both failing) only in its fully formatted output.
        def multiple_exception_lines(presenter)
          lines = presenter.fully_formatted_lines(nil, ::RSpec::Core::Notifications::NullColorizer).map(&:to_s)
          lines = lines.drop_while { |line| line.strip.empty? }
          lines = lines.drop(1) if presenter.description && lines.first&.strip == presenter.description.to_s.strip
          lines.map { |line| line.sub(/\A  /, "") }
        end

        def apply_rspec_configuration
          ::RSpec.configure do |config|
            config.backtrace_exclusion_patterns = config.backtrace_exclusion_patterns | [/lib\/selective/]
            config.silence_filter_announcements = true
          end
        end

        def raise_test_manifest_error(output)
          raise TestManifestError.new("Selective could not generate a test manifest. The output was:\n#{output}")
        end

        def configure(test_case_ids)
          ::RSpec.world.wants_to_quit = false
          ::RSpec.configuration.reset_filters
          ::RSpec.world.filtered_examples.clear

          config.options[:files_or_directories_to_run] = test_case_ids
          rspec_runner.configure($stderr, $stdout)
          ::RSpec.configuration.load_spec_files
        end

        def optimize_test_filtering(test_case_ids)
          # The following is an optimization to avoid RSpec's usual filtering mechanism
          # which has a significant performance overhead.
          test_case_ids.each_with_object(Set.new) do |test_case_id, set|
            example = ::RSpec.world.example_map[test_case_id]
            if ::RSpec.world.filtered_examples.key?(example.example_group)
              ::RSpec.world.filtered_examples[example.example_group] << example
            else
              ::RSpec.world.filtered_examples[example.example_group] = [example]
            end
            set << example.example_group.parent_groups.last
          end
        end

        # RSpec memoizes descendant_filtered_examples per group and decides from it
        # whether to run before(:all)/after(:all); a stale value from an earlier
        # batch skips a group's context hooks.
        def reset_group_memoization(top_level_groups)
          top_level_groups.each { |group| group.descendants.each(&:reset_memoized) }
        end

        def ensure_test_phase
          @test_phase_initialized ||= begin
            ::RSpec.world.reporter.send(:start, nil)
            Selective::Ruby::Core::Controller.suppress_reporting!
            apply_formatter
          end
        end

        def apply_formatter
          config.options[:formatters] << [Selective::Ruby::RSpec::Formatter.to_s]
        end
      end
    end
  end
end
