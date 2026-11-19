# frozen_string_literal: true

RSpec.describe "context hooks across batches" do
  it("top-level example") { expect(true).to be(true) }

  context "nested with setup" do
    before(:all) { @setup = :ran }
    let(:signed_in) { [] }
    before { signed_in << @setup }

    it("runs the nested before(:all) first") { expect(signed_in).to eq([:ran]) }
  end
end
