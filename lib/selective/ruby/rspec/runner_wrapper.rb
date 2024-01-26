require "tempfile"
require "json"

module Selective
  module Ruby
    module RSpec
      class RunnerWrapper
        class TestManifestError < StandardError; end

        attr_reader :rspec_runner, :config, :example_callback

        FRAMEWORK = "rspec"
        DEFAULT_SPEC_PATH = "./spec"

        def initialize(args, example_callback)
          @example_callback = example_callback
          rspec_args, wrapper_config_hash = parse_args(args)
          Selective::Ruby::RSpec::Monkeypatches.apply(wrapper_config_hash)
          apply_rspec_configuration

          @config = ::RSpec::Core::ConfigurationOptions.new(rspec_args)
          if config.options[:files_or_directories_to_run].empty?
            config.options[:files_or_directories_to_run] = [DEFAULT_SPEC_PATH]
          end

          Formatter.callback = method(:report_example)

          @rspec_runner = ::RSpec::Core::Runner.new(@config)
          @rspec_runner.setup($stderr, $stdout)
        end

        def parse_args(args)
          supported_wrapper_args = %w[--require-each-hooks]
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

        def manifest
          output = nil
          Tempfile.create("selective-rspec-dry-run") do |f|
            quoted_paths = config.options[:files_or_directories_to_run].map { |path| "'#{path}'" }.join(" ")
            output = `bundle exec selective exec rspec #{quoted_paths} --format=json --out=#{f.path} --dry-run`
            JSON.parse(f.read).tap do |content|
              if content["examples"].empty?
                message = content["messages"]&.first
                raise_test_manifest_error(message || "No examples found")
              end
            end
          end
        rescue JSON::ParserError => e
          raise_test_manifest_error(e.message)
        end

        def run_test_cases(test_case_ids)
          ::RSpec.world.reporter.send(:start, nil)
          Selective::Ruby::Core::Controller.suppress_reporting!

          ::RSpec.configuration.reset_filters
          ::RSpec.world.prepare_example_filtering
          config.options[:files_or_directories_to_run] = test_case_ids
          ensure_formatter

          rspec_runner.setup($stderr, $stdout)

          example_groups = test_case_ids.each_with_object(Set.new) do |test_case_id, set|
            set << ::RSpec.world.example_map[test_case_id]
          end

          rspec_runner.run_specs(example_groups.to_a)
        end

        def exec
          rspec_runner.run($stderr, $stdout)
        end

        def remove_failed_test_case_result(test_case_id)
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
          ::RSpec.world.reporter.failed_examples.any? ? 1 : 0
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

        private

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

          {
            failure_message_lines: presenter.message_lines,
            failure_formatted_backtrace: presenter.formatted_backtrace
            # failure_full_backtrace: example.exception.backtrace
          }
        end

        def report_example(example)
          example_callback.call(format_example(example))
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

        def ensure_formatter
          formatter = [Selective::Ruby::RSpec::Formatter.to_s]
          return if config.options[:formatters].include?(formatter)

          config.options[:formatters] << formatter
        end
      end
    end
  end
end
