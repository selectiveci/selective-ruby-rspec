# frozen_string_literal: true

RSpec.describe "Model A" do
  it("works") { expect(1).to eq 1 }
  it("same name") { expect(1).to eq 1 }
  it("same name") { expect(1).to eq 1 }
  %w[a b c].each { |l| it("letter #{l}") { expect(l).to be_a(String) } }
  it_behaves_like "a shared thing", 3
  include_examples "a shared thing", 4
  it("slow one", :slow) { expect(1).to eq 1 }
  it("if false", if: false) { raise "never" }
  it("unless true", unless: true) { raise "never" }
  it("skipped") { skip "nope" }
  xit("xed") { raise "never" }
  it("pending without a block")
  context "nested" do
    context "deeper" do
      it("deep") { expect(true).to be true }
    end
  end
  it("focused when asked", focus: ENV["MANIFEST_FOCUSED"] == "1") { expect(1).to eq 1 }
end

RSpec.describe "Model A" do
  it("second group with the same name") { expect(1).to eq 1 }
end
