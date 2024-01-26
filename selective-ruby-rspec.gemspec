# frozen_string_literal: true

require_relative "lib/selective/ruby/rspec/version"

Gem::Specification.new do |spec|
  spec.name = "selective-ruby-rspec"
  spec.version = Selective::Ruby::RSpec::VERSION
  spec.authors = ["Benjamin Wood", "Nate Vick"]
  spec.email = ["ben@hint.io", "nate@hint.io"]
  spec.license = "MIT"

  spec.summary = "Selective Ruby RSpec Client"
  spec.description = "Selective is an intelligent test runner for your current CI provider. Get real-time test results, intelligent ordering based on code changes, shorter run times, automatic flake detection, the ability to re-enqueue failed tests, and more."
  spec.homepage = "https://www.selective.ci"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://github.com/selectiveci/selective-ruby-rspec"
  spec.metadata["changelog_uri"] = "https://github.com/selectiveci/selective-ruby-rspec/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ log/ gemfiles/ .git .circleci appveyor .rspec .ruby-version .standard.yml README.md CHANGELOG.md CODE_OF_CONDUCT.md Gemfile Appraisals])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency("zeitwerk", "~> 2.6.12")
  spec.add_dependency("selective-ruby-core", ">= 0.2.2")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
