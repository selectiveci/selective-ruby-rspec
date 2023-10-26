# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in selective-ruby-rspec.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "standard", "~> 1.3"

gem "irb"

gem "rspec_junit_formatter"

gem "appraisal", "~> 2.5"

gem "simplecov", require: false, group: :test

if Dir.exist?(selective_ruby_core_path = "../selective-ruby-core")
  gem "selective-ruby-core", path: selective_ruby_core_path
else
  gem "selective-ruby-core", git: "https://#{ENV["CLONE_PAT"]}:@github.com/selectiveci/selective-ruby-core.git"
end
