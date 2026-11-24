# frozen_string_literal: true

RSpec.describe "Requests B", type: :request do
  it("get") { expect(1).to eq 1 }
  it("post") { expect(2).to eq 2 }
  describe "nested request" do
    it("put") { expect(3).to eq 3 }
  end
end
