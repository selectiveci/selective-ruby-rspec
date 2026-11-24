# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"

RSpec.describe "the test manifest" do
  root = File.expand_path("../../../..", __dir__)
  fixtures = "spec/fixtures/manifest"
  base = ["--require", "./#{fixtures}/helper", "--pattern", "**/*_cases.rb"]

  define_method(:selective_manifest) do |args, env = {}|
    output, status = Open3.capture2e(env, "bundle", "exec", "ruby", "-Ilib", "spec/fixtures/print_manifest.rb", *args, chdir: root)
    raise output unless status.success?

    JSON.parse(output.lines.last)
  end

  define_method(:dry_run_ids) do |args, env = {}|
    Tempfile.create(["dry-run", ".json"]) do |f|
      Open3.capture2e(env, "bundle", "exec", "rspec", *args, "--dry-run", "--format", "json", "--out", f.path, chdir: root)
      JSON.parse(File.read(f.path))["examples"].map { |e| e["id"] }
    end
  end

  {
    "the whole suite" => [["#{fixtures}/suite"], {}],
    "a location filter" => [["#{fixtures}/suite/models", "#{fixtures}/suite/requests/b_cases.rb:5"], {}],
    "an id filter" => [["#{fixtures}/suite/models/a_cases.rb[1:2]"], {}],
    "a tag on the command line" => [["#{fixtures}/suite", "--tag", "type:request"], {}],
    "a tag in SPEC_OPTS" => [["#{fixtures}/suite"], {"SPEC_OPTS" => "--tag type:request"}],
    "an exclude pattern" => [["#{fixtures}/suite", "--exclude-pattern", "**/requests/**"], {}],
    "a focused example" => [["#{fixtures}/suite"], {"MANIFEST_FOCUS" => "when_matching", "MANIFEST_FOCUSED" => "1"}],
    "a focus filter that matches nothing" => [["#{fixtures}/suite"], {"MANIFEST_FOCUS" => "when_matching"}]
  }.each do |name, (paths, env)|
    it "lists what a dry run lists with #{name}" do
      args = base + paths
      expected = dry_run_ids(args, env)
      expect(expected).not_to be_empty
      expect(selective_manifest(args, env)["ids"]).to match_array(expected)
    end
  end

  context "with run_all_when_everything_filtered" do
    before { skip "removed in RSpec 4" unless ::RSpec.configuration.respond_to?(:run_all_when_everything_filtered=) }

    it "lists everything when the inclusion filter matches nothing" do
      args = base + ["#{fixtures}/suite"]
      env = {"MANIFEST_FOCUS" => "run_all"}
      expect(selective_manifest(args, env)["ids"]).to match_array(dry_run_ids(args, env))
    end

    it "lists only the focused examples when something matches" do
      args = base + ["#{fixtures}/suite"]
      env = {"MANIFEST_FOCUS" => "run_all", "MANIFEST_FOCUSED" => "1"}
      ids = selective_manifest(args, env)["ids"]
      expect(ids).to eq(dry_run_ids(args, env))
      expect(ids.size).to eq(1)
    end
  end

  it "reports a spec file that fails to load" do
    result = selective_manifest(base + ["#{fixtures}/suite", "#{fixtures}/broken"])
    expect(result["error"]).to include("An error occurred while loading ./#{fixtures}/broken/broken_cases.rb")
    expect(result["error"]).to include("UndefinedConstantInACaseFile")
  end

  it "reports a path that doesn't exist" do
    expect(selective_manifest(base + ["#{fixtures}/missing_cases.rb"])["error"]).to include("missing_cases.rb")
  end

  it "reports a suite with no examples" do
    expect(selective_manifest(base + ["#{fixtures}/empty"])["error"]).to include("No examples found")
  end
end
