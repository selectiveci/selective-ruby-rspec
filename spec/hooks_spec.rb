RSpec.describe "Before/after hooks" do
  before(:all) { @outer_before_all = true }
  before(:each) { @outer_before_each = true }

  after(:all) { expect(@outer_after_all).to eq(true) }
  after(:each) { expect(@outer_after_each).to eq(true) }

  it 'runs in outter context' do
    expect(@outer_before_all).to eq(true)
    expect(@outer_before_each).to eq(true)
    @outer_after_all = true
    @outer_after_each = true
  end

  context 'when defined in a nested context' do
    before(:all) { @inner_before_all = true }
    before(:each) { @inner_before_each = true }

    after(:all) { expect(@inner_after_all).to eq(true) }
    after(:each) { expect(@inner_after_each).to eq(true) }

    it 'runs hooks in innter context' do
      expect(@inner_before_all).to eq(true)
      expect(@inner_before_each).to eq(true)
      @inner_after_all = true
      @inner_after_each = true
      @outer_after_all = true
      @outer_after_each = true
    end
  end
end