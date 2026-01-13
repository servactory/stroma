# frozen_string_literal: true

RSpec.describe Stroma::Matrix do
  describe "#initialize" do
    it "creates a frozen matrix with name" do
      matrix = described_class.new(:test) do
        register :inputs, Module.new
      end

      expect(matrix.name).to eq(:test)
      expect(matrix).to be_frozen
    end

    it "finalizes registry automatically" do
      matrix = described_class.new(:test) do
        register :inputs, Module.new
      end

      expect(matrix.registry).to be_a(Stroma::Registry)
      expect(matrix.keys).to eq([:inputs])
    end
  end

  describe "#register" do
    it "delegates to registry" do
      matrix = described_class.new(:test) do
        register :inputs, Module.new
        register :outputs, Module.new
      end

      expect(matrix.keys).to eq(%i[inputs outputs])
    end
  end

  describe "#dsl" do
    let(:matrix) do
      described_class.new(:test) do
        register :inputs, Module.new
      end
    end

    it "returns a module" do
      expect(matrix.dsl).to be_a(Module)
    end

    it "caches the module" do
      expect(matrix.dsl).to be(matrix.dsl)
    end
  end

  describe "isolation" do
    let(:matrix_a) do
      described_class.new(:lib_a) do
        register :inputs, Module.new
        register :outputs, Module.new
      end
    end

    let(:matrix_b) do
      described_class.new(:lib_b) do
        register :inputs, Module.new
        register :events, Module.new
      end
    end

    it "has independent registries", :aggregate_failures do
      expect(matrix_a.keys).to eq(%i[inputs outputs])
      expect(matrix_b.keys).to eq(%i[inputs events])
    end

    it "allows same keys in different matrices" do
      expect { matrix_a; matrix_b }.not_to raise_error
    end
  end
end
