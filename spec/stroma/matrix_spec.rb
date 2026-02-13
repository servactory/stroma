# frozen_string_literal: true

RSpec.describe Stroma::Matrix do
  describe ".define" do
    it "creates a frozen matrix with name", :aggregate_failures do
      matrix = described_class.define(:test) do
        register :inputs, Module.new
      end

      expect(matrix.name).to eq(:test)
      expect(matrix).to be_frozen
    end

    it "is equivalent to .new", :aggregate_failures do
      inputs_mod = Module.new

      matrix_via_define = described_class.define(:test) do
        register :inputs, inputs_mod
      end

      matrix_via_new = described_class.new(:test) do
        register :inputs, inputs_mod
      end

      expect(matrix_via_define.name).to eq(matrix_via_new.name)
      expect(matrix_via_define.keys).to eq(matrix_via_new.keys)
    end
  end

  describe "#initialize" do
    it "creates a frozen matrix with name", :aggregate_failures do
      matrix = described_class.new(:test) do
        register :inputs, Module.new
      end

      expect(matrix.name).to eq(:test)
      expect(matrix).to be_frozen
    end

    it "finalizes registry automatically", :aggregate_failures do
      matrix = described_class.new(:test) do
        register :inputs, Module.new
      end

      expect(matrix.registry).to be_a(Stroma::Registry)
      expect(matrix.keys).to eq([:inputs])
    end
  end

  describe "validate_name!" do
    it "accepts valid lowercase names" do
      expect { described_class.new(:test) }.not_to raise_error
    end

    it "accepts names with underscores" do
      expect { described_class.new(:my_lib) }.not_to raise_error
    end

    it "accepts names starting with underscore" do
      expect { described_class.new(:_private) }.not_to raise_error
    end

    it "accepts names with digits" do
      expect { described_class.new(:lib2) }.not_to raise_error
    end

    it "raises InvalidMatrixName for names starting with digit" do
      expect { described_class.new(:"123invalid") }.to raise_error(
        Stroma::Exceptions::InvalidMatrixName,
        "Invalid matrix name: :\"123invalid\". Must match /\\A[a-z_][a-z0-9_]*\\z/"
      )
    end

    it "raises InvalidMatrixName for names with uppercase" do
      expect { described_class.new(:MyLib) }.to raise_error(
        Stroma::Exceptions::InvalidMatrixName,
        "Invalid matrix name: :MyLib. Must match /\\A[a-z_][a-z0-9_]*\\z/"
      )
    end

    it "raises InvalidMatrixName for names with dashes" do
      expect { described_class.new(:"my-lib") }.to raise_error(
        Stroma::Exceptions::InvalidMatrixName,
        "Invalid matrix name: :\"my-lib\". Must match /\\A[a-z_][a-z0-9_]*\\z/"
      )
    end

    it "raises InvalidMatrixName for empty name" do
      expect { described_class.new(:"") }.to raise_error(
        Stroma::Exceptions::InvalidMatrixName,
        "Invalid matrix name: :\"\". Must match /\\A[a-z_][a-z0-9_]*\\z/"
      )
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
      expect do
        matrix_a
        matrix_b
      end.not_to raise_error
    end
  end
end
