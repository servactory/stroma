# frozen_string_literal: true

RSpec.describe Stroma::Hooks::Wrap do
  subject(:wrap) { described_class.new(target_key: :actions, extension: test_module) }

  let(:test_module) { Module.new }

  describe ".new" do
    it { expect(wrap.target_key).to eq(:actions) }
    it { expect(wrap.extension).to eq(test_module) }
  end

  describe "immutability" do
    it "is frozen" do
      expect(wrap).to be_frozen
    end
  end

  describe "equality" do
    let(:same_wrap) { described_class.new(target_key: :actions, extension: test_module) }
    let(:different_key_wrap) { described_class.new(target_key: :inputs, extension: test_module) }
    let(:different_module) { Module.new }
    let(:different_extension_wrap) { described_class.new(target_key: :actions, extension: different_module) }

    it "is equal to wrap with same key and extension" do
      expect(wrap).to eq(same_wrap)
    end

    it "is not equal to wrap with different key" do
      expect(wrap).not_to eq(different_key_wrap)
    end

    it "is not equal to wrap with different extension" do
      expect(wrap).not_to eq(different_extension_wrap)
    end
  end
end
