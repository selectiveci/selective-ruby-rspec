require "tempfile"
require "json"

module Selective
  module Ruby
    module RSpec
      class RunnerWrapper
        class TestManifestError < StandardError; end

        attr_reader :args, :rspec_runner, :config

        DEFAULT_SPEC_PATH = "./spec"

        def initialize(args)
          Selective::Ruby::RSpec::Monkeypatches.apply
          apply_rspec_configuration

          args << "--format=progress" unless args.any? { |e| e.start_with?("--format") }
          @args = args

          @config = ::RSpec::Core::ConfigurationOptions.new(args)
          if config.options[:files_or_directories_to_run].empty?
            config.options[:files_or_directories_to_run] = [DEFAULT_SPEC_PATH]
          end

          @rspec_runner = ::RSpec::Core::Runner.new(@config)
          @rspec_runner.setup($stderr, $stdout)
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

        def run_test_cases(test_case_ids, callback)
          ::RSpec.world.reporter.send(:start, nil)
          Selective::Ruby::Core::Controller.suppress_reporting!
          test_case_ids.flatten.each do |test_case_id|
            run_test_case(test_case_id, callback)
          end
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

        private

        def run_test_case(test_case_id, callback)
          ::RSpec.configuration.reset_filters
          ::RSpec.world.prepare_example_filtering
          config.options[:files_or_directories_to_run] = test_case_id
          rspec_runner.options = config
          rspec_runner.setup($stderr, $stdout)

          # $rspec_rerun_debug = true if test_case == './spec/selective_spec.rb[1:2]' && ::RSpec.world.reporter.examples.length == 5
          rspec_runner.run_specs([::RSpec.world.example_map[test_case_id]])
          callback.call(format_example(get_example_from_reporter(test_case_id)))
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

          {
            failure_message_lines: presenter.message_lines,
            failure_formatted_backtrace: presenter.formatted_backtrace
            # failure_full_backtrace: example.exception.backtrace
          }
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
      end
    end
  end
end
