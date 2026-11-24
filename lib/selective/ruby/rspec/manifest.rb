# frozen_string_literal: true

module Selective
  module Ruby
    module RSpec
      # The examples a dry run of the loaded suite would list, read from this
      # process's world: RSpec's own filtering over every loaded group, with
      # nothing run. Captured in World#announce_filters, which clears the
      # groups (and can clear inclusion filters) right after.
      class Manifest
        attr_reader :examples

        def self.capture(world)
          new(world).tap(&:capture)
        end

        def initialize(world)
          @world = world
          @load_errors = world.selective_load_errors.dup
          @quitting = world.wants_to_quit || (world.respond_to?(:rspec_is_quitting) && world.rspec_is_quitting)
          @examples = []
        end

        def capture
          filter_manager = @world.filter_manager
          examples = select(filter_manager)

          if examples.empty? && run_all_when_everything_filtered?
            # announce_filters does the same next, in this process as in a dry run.
            filter_manager.inclusions.clear
            examples = select(filter_manager)
          end

          @examples = examples.map do |example|
            {
              "id" => example.id,
              "file_path" => example.metadata[:file_path],
              "line_number" => example.metadata[:line_number]
            }
          end
        end

        def failed_to_load?
          @quitting || @load_errors.any?
        end

        # As RSpec prints them.
        def load_errors
          @load_errors.map do |exception, context_description|
            example = ::RSpec::Core::Example.new(::RSpec::Core::AnonymousExampleGroup, context_description, {})
            ::RSpec::Core::Formatters::ExceptionPresenter.new(exception, example, indentation: 0).fully_formatted(nil)
          end
        end

        private

        def select(filter_manager)
          @world.example_groups.flat_map(&:descendants).flat_map do |group|
            filter_manager.prune(group.examples)
          end
        end

        # Removed in RSpec 4.
        def run_all_when_everything_filtered?
          configuration = ::RSpec.configuration
          configuration.respond_to?(:run_all_when_everything_filtered?) &&
            configuration.run_all_when_everything_filtered? && !configuration.only_failures?
        end
      end
    end
  end
end
