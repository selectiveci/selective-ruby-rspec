# frozen_string_literal: true

require "zeitwerk"
require "rspec/core"
require "#{__dir__}/selective/ruby/rspec/version"

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect("rspec" => "RSpec")
loader.ignore("#{__dir__}/selective-ruby-rspec.rb")
loader.ignore("#{__dir__}/selective/ruby/rspec/version.rb")
loader.setup

require "selective-ruby-core"

module Selective
  module Ruby
    module RSpec
      class Error < StandardError; end

      def self.register
        Selective::Ruby::Core.register_runner(
          "rspec", Selective::Ruby::RSpec::RunnerWrapper
        )
      end
    end
  end
end

Selective::Ruby::RSpec.register
