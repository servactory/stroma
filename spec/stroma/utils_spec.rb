# frozen_string_literal: true

RSpec.describe Stroma::Utils do
  describe ".label_module" do
    let(:mod) { Module.new }
    let(:label) { "Stroma::Test(example)" }

    before { described_class.label_module(mod, label) }

    it "sets inspect to the label" do
      expect(mod.inspect).to eq(label)
    end

    it "sets to_s to the label" do
      expect(mod.to_s).to eq(label)
    end
  end
end
