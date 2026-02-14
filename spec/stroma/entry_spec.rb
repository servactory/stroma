# frozen_string_literal: true

RSpec.describe Stroma::Entry do
  subject(:entry) { described_class.new(key: :test, extension: test_module, matrix_name: :my_lib) }

  let(:test_module) { Module.new }

  describe ".new" do
    it { expect(entry.key).to eq(:test) }
    it { expect(entry.extension).to eq(test_module) }
    it { expect(entry.matrix_name).to eq(:my_lib) }
  end

  describe "#phase_method" do
    it "returns symbol combining matrix_name and key" do
      expect(entry.phase_method).to eq(:_my_lib_phase_test!)
    end

    it "handles different matrix names" do
      other = described_class.new(key: :actions, extension: test_module, matrix_name: :servactory)
      expect(other.phase_method).to eq(:_servactory_phase_actions!)
    end
  end

  describe "immutability" do
    it "is frozen" do
      expect(entry).to be_frozen
    end
  end

  describe "equality" do
    let(:same_entry) { described_class.new(key: :test, extension: test_module, matrix_name: :my_lib) }
    let(:different_key_entry) { described_class.new(key: :other, extension: test_module, matrix_name: :my_lib) }
    let(:different_module) { Module.new }
    let(:different_extension_entry) do
      described_class.new(key: :test, extension: different_module, matrix_name: :my_lib)
    end
    let(:different_matrix_entry) { described_class.new(key: :test, extension: test_module, matrix_name: :other_lib) }

    it "is equal to entry with same key, extension, and matrix_name" do
      expect(entry).to eq(same_entry)
    end

    it "is not equal to entry with different key" do
      expect(entry).not_to eq(different_key_entry)
    end

    it "is not equal to entry with different extension" do
      expect(entry).not_to eq(different_extension_entry)
    end

    it "is not equal to entry with different matrix_name" do
      expect(entry).not_to eq(different_matrix_entry)
    end

    it "has same hash for equal entries" do
      expect(entry.hash).to eq(same_entry.hash)
    end
  end
end
