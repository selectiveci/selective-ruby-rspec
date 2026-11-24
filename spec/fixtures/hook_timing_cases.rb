# frozen_string_literal: true

RSpec.describe "a group with costly shared setup" do
  before(:all) { sleep 0.05 }

  it("one") { expect(1).to eq 1 }
  it("two") { expect(2).to eq 2 }
  it("three") { expect(3).to eq 3 }
end
