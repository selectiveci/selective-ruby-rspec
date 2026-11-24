# frozen_string_literal: true

module Selective
  module Ruby
    module RSpec
      # Time in before(:all)/after(:all) hooks, which run outside any example,
      # per group per batch. A group split across batches runs its hooks once
      # per batch; `context_hook_rerun_ms` is the time past each group's first
      # run, the cost of that split.
      module ContextHookTiming
        @seen = {}
        @totals = {"context_hook_ms" => 0.0, "context_hook_rerun_ms" => 0.0, "context_hook_groups" => 0, "context_hook_runs" => 0}

        class << self
          # One call per group per batch for each of before and after; a
          # group's second before-run is the first rerun.
          def record(group, position, ms)
            @totals["context_hook_ms"] += ms
            if position == :before
              @totals["context_hook_runs"] += 1
              @seen[group] = @seen.key?(group) ? :rerun : :first
              @totals["context_hook_groups"] += 1 if @seen[group] == :first
            end
            @totals["context_hook_rerun_ms"] += ms if @seen[group] == :rerun
          end

          def report
            @totals.transform_values { |v| v.is_a?(Float) ? v.round : v }
          end

          def reset
            @seen = {}
            @totals.each_key { |k| @totals[k] = k.end_with?("_ms") ? 0.0 : 0 }
          end
        end

        # Prepended to ExampleGroup's singleton class: per-group class methods.
        module GroupMethods
          def run_before_context_hooks(example_group_instance)
            context_hooks? ? timed(:before) { super } : super
          end

          def run_after_context_hooks(example_group_instance)
            context_hooks? ? timed(:after) { super } : super
          end

          private

          # RSpec creates these collections when the first hook is registered.
          def context_hooks?
            hooks.instance_variable_get(:@before_context_hooks) || hooks.instance_variable_get(:@after_context_hooks)
          end

          def timed(position)
            started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            yield
          ensure
            ContextHookTiming.record(self, position, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000)
          end
        end
      end
    end
  end
end
