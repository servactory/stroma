# frozen_string_literal: true

RSpec.describe Stroma::Phase::Wrap do
  subject(:wrap) { described_class.new(target_key: :actions, block: test_block) }

  let(:test_block) { proc { |phase, **kwargs| phase.call(**kwargs) } }

  describe ".new" do
    it { expect(wrap.target_key).to eq(:actions) }
    it { expect(wrap.block).to eq(test_block) }
  end

  describe "immutability" do
    it "is frozen" do
      expect(wrap).to be_frozen
    end
  end
end
