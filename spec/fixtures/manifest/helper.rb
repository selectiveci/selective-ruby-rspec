# frozen_string_literal: true

RSpec.shared_examples "a shared thing" do |n|
  it("has n #{n}") { expect(n).to be_a(Integer) }
  it("is shared") { expect(true).to be true }
end

RSpec.configure do |c|
  c.filter_run_excluding :slow
  case ENV["MANIFEST_FOCUS"]
  when "when_matching" then c.filter_run_when_matching :focus
  when "run_all"
    c.filter_run :focus
    c.run_all_when_everything_filtered = true
  end
end
