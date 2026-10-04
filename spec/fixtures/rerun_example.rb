# frozen_string_literal: true

module RerunOutcomes
  SEQUENCE = ENV.fetch("RERUN_OUTCOMES", "").split(",")

  def self.next
    @attempt = @attempt.to_i + 1
    SEQUENCE.fetch(@attempt - 1)
  end
end

RSpec.describe "an example rerun on the same runner" do
  it "has the outcome its attempt was given" do
    expect(RerunOutcomes.next).to eq("pass")
  end
end
