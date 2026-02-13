# frozen_string_literal: true

RSpec.describe Stroma::Hooks::Collection do
  let(:hooks) { described_class.new }
  let(:first_module) { Module.new }
  let(:second_module) { Module.new }

  describe "#add" do
    it "adds a wrap to the collection" do
      hooks.add(:actions, first_module)
      expect(hooks.for(:actions).size).to eq(1)
    end

    it "allows multiple wraps for the same key" do
      hooks.add(:actions, first_module)
      hooks.add(:actions, second_module)
      expect(hooks.for(:actions).size).to eq(2)
    end
  end

  describe "#for" do
    before do
      hooks.add(:actions, first_module)
      hooks.add(:outputs, second_module)
    end

    it "returns wraps for the specified key", :aggregate_failures do
      result = hooks.for(:actions)
      expect(result.size).to eq(1)
      expect(result.first.extension).to eq(first_module)
    end

    it "returns empty array for key without wraps" do
      expect(hooks.for(:inputs)).to eq([])
    end
  end

  describe "#empty?" do
    it "returns true for new hooks collection" do
      expect(hooks.empty?).to be(true)
    end

    it "returns false after adding a wrap" do
      hooks.add(:actions, first_module)
      expect(hooks.empty?).to be(false)
    end
  end

  describe "#dup (via initialize_dup)" do
    let(:copy) { hooks.dup }

    before do
      hooks.add(:actions, first_module)
      hooks.add(:outputs, second_module)
    end

    it "creates a copy with the same wraps", :aggregate_failures do
      expect(copy.for(:actions).size).to eq(1)
      expect(copy.for(:outputs).size).to eq(1)
    end

    it "creates an independent copy", :aggregate_failures do
      copy.add(:inputs, second_module)
      expect(hooks.for(:inputs)).to be_empty
      expect(copy.for(:inputs).size).to eq(1)
    end
  end

  describe "#size" do
    it "returns 0 for new collection" do
      expect(hooks.size).to eq(0)
    end

    it "returns count of wraps" do
      hooks.add(:actions, first_module)
      hooks.add(:actions, second_module)
      expect(hooks.size).to eq(2)
    end
  end

  describe "#each" do
    before do
      hooks.add(:actions, first_module)
      hooks.add(:outputs, second_module)
    end

    it "yields each wrap" do
      expect(hooks.map(&:itself).size).to eq(2)
    end

    it "yields Wrap objects" do
      expect(hooks.map(&:itself)).to all(be_a(Stroma::Hooks::Wrap))
    end
  end

  describe "protected interface" do
    it "does not expose collection publicly" do
      expect { hooks.collection }.to raise_error(NoMethodError)
    end
  end
end
