# frozen_string_literal: true

RSpec.describe Stroma::Phase::Wrappable do
  let(:extension) do
    Module.new do
      extend Stroma::Phase::Wrappable
    end
  end

  describe "#wrap_phase" do
    it "registers a phase wrap" do
      extension.wrap_phase(:actions) { |phase, **kwargs| phase.call(**kwargs) }
      expect(extension.stroma_phase_wraps.size).to eq(1)
    end

    it "creates a Phase::Wrap with correct target_key" do
      extension.wrap_phase(:actions) { |phase, **kwargs| phase.call(**kwargs) }
      expect(extension.stroma_phase_wraps.first.target_key).to eq(:actions)
    end

    it "stores the block" do
      extension.wrap_phase(:actions) { |phase, **kwargs| phase.call(**kwargs) }
      expect(extension.stroma_phase_wraps.first.block).to be_a(Proc)
    end

    it "allows multiple wraps for different keys" do
      extension.wrap_phase(:actions) { |phase, **kwargs| phase.call(**kwargs) }
      extension.wrap_phase(:inputs) { |phase, **kwargs| phase.call(**kwargs) }
      expect(extension.stroma_phase_wraps.size).to eq(2)
    end
  end

  describe "#stroma_phase_wraps" do
    it "returns empty array by default" do
      expect(extension.stroma_phase_wraps).to eq([])
    end
  end
end
