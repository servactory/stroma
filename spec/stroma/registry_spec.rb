# frozen_string_literal: true

RSpec.describe Stroma::Registry do
  describe "#initialize" do
    it "creates registry with matrix name" do
      registry = described_class.new(:test)
      expect(registry.matrix_name).to eq(:test)
    end
  end

  describe "#register" do
    let(:registry) { described_class.new(:test) }

    it "adds entry to registry" do
      extension = Module.new
      registry.register(:inputs, extension)
      registry.finalize!

      expect(registry.keys).to eq([:inputs])
    end

    it "raises KeyAlreadyRegistered for duplicate key" do
      registry.register(:inputs, Module.new)

      expect { registry.register(:inputs, Module.new) }.to raise_error(
        Stroma::Exceptions::KeyAlreadyRegistered,
        "Key :inputs already registered in :test"
      )
    end

    it "raises RegistryFrozen when finalized" do
      registry.finalize!

      expect { registry.register(:test, Module.new) }.to raise_error(
        Stroma::Exceptions::RegistryFrozen,
        "Registry for :test is finalized"
      )
    end
  end

  describe "#finalize!" do
    let(:registry) { described_class.new(:test) }

    it "is idempotent" do
      registry.register(:inputs, Module.new)
      registry.finalize!

      expect { registry.finalize! }.not_to raise_error
    end

    it "freezes entries" do
      registry.register(:inputs, Module.new)
      registry.finalize!

      expect(registry.entries).to be_frozen
    end
  end

  describe "#entries" do
    let(:registry) { described_class.new(:test) }

    it "raises RegistryNotFinalized before finalize" do
      registry.register(:inputs, Module.new)

      expect { registry.entries }.to raise_error(
        Stroma::Exceptions::RegistryNotFinalized,
        "Registry for :test not finalized"
      )
    end

    it "returns entries after finalize", :aggregate_failures do
      extension = Module.new
      registry.register(:inputs, extension)
      registry.finalize!

      expect(registry.entries.first.key).to eq(:inputs)
      expect(registry.entries.first.extension).to eq(extension)
    end
  end

  describe "#keys" do
    let(:registry) { described_class.new(:test) }

    it "returns all registered keys" do
      registry.register(:inputs, Module.new)
      registry.register(:outputs, Module.new)
      registry.finalize!

      expect(registry.keys).to eq(%i[inputs outputs])
    end
  end

  describe "#key?" do
    let(:registry) { described_class.new(:test) }

    before do
      registry.register(:inputs, Module.new)
      registry.finalize!
    end

    it "returns true for registered key" do
      expect(registry.key?(:inputs)).to be(true)
    end

    it "returns false for unregistered key" do
      expect(registry.key?(:unknown)).to be(false)
    end
  end
end
