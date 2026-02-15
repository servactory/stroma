# frozen_string_literal: true

RSpec.describe Stroma::DSL::Generator do
  let(:inputs_dsl) { Module.new }
  let(:outputs_dsl) { Module.new }

  let(:matrix) do
    inputs = inputs_dsl
    outputs = outputs_dsl
    Stroma::Matrix.define(:test) do
      register :inputs, inputs
      register :outputs, outputs
    end
  end

  describe ".call" do
    let(:dsl_module) { described_class.call(matrix) }

    it "returns a module" do
      expect(dsl_module).to be_a(Module)
    end

    it "stores matrix reference" do
      expect(dsl_module.stroma_matrix).to eq(matrix)
    end

    describe "module labeling" do
      it "labels DSL module with matrix name", :aggregate_failures do
        expect(dsl_module.inspect).to eq("Stroma::DSL(test)")
        expect(dsl_module.to_s).to eq("Stroma::DSL(test)")
      end

      it "labels ClassMethods with matrix name", :aggregate_failures do
        class_methods = dsl_module.const_get(:ClassMethods)
        expect(class_methods.inspect).to include("Stroma::DSL(test)")
        expect(class_methods.inspect).to include("ClassMethods")
      end

      if Module.new.respond_to?(:set_temporary_name)
        it "sets module name via set_temporary_name" do
          expect(dsl_module.name).to eq("Stroma::DSL(test)")
        end
      end
    end
  end

  describe "generated module" do
    let(:base_class) do
      mtx = matrix
      Class.new { include mtx.dsl }
    end

    it "extends class with ClassMethods", :aggregate_failures do
      expect(base_class).to respond_to(:stroma)
      expect(base_class).to respond_to(:stroma_matrix)
      expect(base_class).to respond_to(:inherited)
    end

    it "does not include entry modules in base ancestors", :aggregate_failures do
      expect(base_class.ancestors).not_to include(inputs_dsl)
      expect(base_class.ancestors).not_to include(outputs_dsl)
    end

    it "creates stroma state" do
      expect(base_class.stroma).to be_a(Stroma::State)
    end

    it "stores matrix reference on class" do
      expect(base_class.stroma_matrix).to eq(matrix)
    end
  end

  describe "inheritance" do
    let(:extension_module) do
      Module.new do
        def self.included(base)
          base.define_singleton_method(:extension_method) { :extension_result }
        end
      end
    end

    let(:base_class) do
      mtx = matrix
      ext = extension_module
      Class.new do
        include mtx.dsl

        extensions do
          before :inputs, ext
        end
      end
    end

    let(:child_class) { Class.new(base_class) }

    it "includes entry modules in child via interleaving", :aggregate_failures do
      expect(child_class.ancestors).to include(inputs_dsl)
      expect(child_class.ancestors).to include(outputs_dsl)
    end

    it "applies hooks to child class" do
      expect(child_class.ancestors).to include(extension_module)
    end

    it "positions hook adjacent to its target entry in child" do
      ancestors = child_class.ancestors
      expect(ancestors.index(extension_module)).to be < ancestors.index(inputs_dsl)
    end

    it "child has extension method", :aggregate_failures do
      expect(child_class).to respond_to(:extension_method)
      expect(child_class.extension_method).to eq(:extension_result)
    end

    it "copies stroma state to child", :aggregate_failures do
      expect(child_class.stroma).not_to eq(base_class.stroma)
      expect(child_class.stroma).to be_a(Stroma::State)
    end

    it "preserves matrix reference" do
      expect(child_class.stroma_matrix).to eq(matrix)
    end
  end

  describe "multi-level inheritance" do
    let(:base_class) do
      mtx = matrix
      Class.new { include mtx.dsl }
    end

    context "with hooks at one level" do
      let(:auth_module) do
        Module.new do
          def self.included(base)
            base.define_singleton_method(:auth_configured) { true }
          end
        end
      end

      let(:mid_class) do
        base = base_class
        auth = auth_module
        Class.new(base) do
          extensions do
            before :inputs, auth
          end
        end
      end

      let(:leaf_class) { Class.new(mid_class) }

      it "defers entries in base (no hooks)", :aggregate_failures do
        expect(base_class.ancestors).not_to include(inputs_dsl)
        expect(base_class.ancestors).not_to include(outputs_dsl)
      end

      it "defers entries in mid class (hooks registered but not applied yet)", :aggregate_failures do
        expect(mid_class.ancestors).not_to include(inputs_dsl)
        expect(mid_class.ancestors).not_to include(outputs_dsl)
      end

      it "interleaves entries with hooks in leaf class", :aggregate_failures do
        ancestors = leaf_class.ancestors

        expect(ancestors).to include(inputs_dsl, outputs_dsl, auth_module)
        expect(ancestors.index(auth_module)).to be < ancestors.index(inputs_dsl)
      end

      it "propagates hook class methods to leaf via interleaving" do
        expect(leaf_class).to respond_to(:auth_configured)
      end
    end

    context "with hooks at every level" do
      let(:auth_module) { Module.new }
      let(:logging_module) { Module.new }

      let(:mid_class) do
        base = base_class
        auth = auth_module
        Class.new(base) do
          extensions do
            before :inputs, auth
          end
        end
      end

      let(:leaf_class) do
        mid = mid_class
        logging = logging_module
        Class.new(mid) do
          extensions do
            after :inputs, logging
          end
        end
      end

      it "grandchild inherits hooks from all levels", :aggregate_failures do
        grandchild = Class.new(leaf_class)

        expect(grandchild.ancestors).to include(auth_module)
        expect(grandchild.ancestors).to include(logging_module)
        expect(grandchild.ancestors).to include(inputs_dsl)
        expect(grandchild.ancestors).to include(outputs_dsl)
      end
    end

    context "when grandchild has no own hooks" do
      let(:auth_module) { Module.new }

      let(:mid_class) do
        base = base_class
        auth = auth_module
        Class.new(base) do
          extensions do
            before :inputs, auth
          end
        end
      end

      let(:child_class) { Class.new(mid_class) }
      let(:grandchild) { Class.new(child_class) }

      it "entries propagate to grandchild via ancestors", :aggregate_failures do
        expect(grandchild.ancestors).to include(inputs_dsl)
        expect(grandchild.ancestors).to include(outputs_dsl)
        expect(grandchild.ancestors).to include(auth_module)
      end
    end
  end

  describe "inheritance isolation" do
    let(:extension_module) { Module.new }

    let(:base_class) do
      mtx = matrix
      ext = extension_module
      Class.new do
        include mtx.dsl

        extensions do
          before :inputs, ext
        end
      end
    end

    let(:child_class) { Class.new(base_class) }

    it "child modifications do not affect base", :aggregate_failures do
      child_extension = Module.new

      child_class.class_eval do
        extensions do
          after :outputs, child_extension
        end
      end

      expect(base_class.stroma.hooks.after(:outputs)).to be_empty
      expect(child_class.stroma.hooks.after(:outputs)).not_to be_empty
    end

    it "child inherits base hooks", :aggregate_failures do
      expect(child_class.stroma.hooks.before(:inputs).size).to eq(1)
      expect(child_class.ancestors).to include(extension_module)
    end

    it "base modifications after child creation do not affect child" do
      child_before_count = child_class.stroma.hooks.before(:outputs).size
      new_extension = Module.new

      base_class.class_eval do
        extensions do
          before :outputs, new_extension
        end
      end

      expect(child_class.stroma.hooks.before(:outputs).size).to eq(child_before_count)
    end
  end
end
