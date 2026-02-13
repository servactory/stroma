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

    it "includes all registered DSL modules", :aggregate_failures do
      expect(base_class.ancestors).to include(inputs_dsl)
      expect(base_class.ancestors).to include(outputs_dsl)
    end

    it "creates stroma state" do
      expect(base_class.stroma).to be_a(Stroma::State)
    end

    it "stores matrix reference on class" do
      expect(base_class.stroma_matrix).to eq(matrix)
    end
  end

  describe "phase stubs and orchestrator" do
    let(:base_class) do
      mtx = matrix
      Class.new { include mtx.dsl }
    end

    it "defines phase methods as private" do
      instance = base_class.new
      expect(instance.private_methods).to include(:_test_phase_inputs!, :_test_phase_outputs!)
    end

    it "defines orchestrator as private" do
      instance = base_class.new
      expect(instance.private_methods).to include(:_test_phases_perform!)
    end

    it "orchestrator calls all phases in order" do
      call_order = []
      co = call_order

      inputs_mod = Module.new do
        define_method(:_test_phase_inputs!) do |**|
          co << :inputs
        end
      end

      outputs_mod = Module.new do
        define_method(:_test_phase_outputs!) do |**|
          co << :outputs
        end
      end

      mtx = Stroma::Matrix.define(:test) do
        register :inputs, inputs_mod
        register :outputs, outputs_mod
      end

      klass = Class.new { include mtx.dsl }
      klass.new.send(:_test_phases_perform!)

      expect(call_order).to eq(%i[inputs outputs])
    end

    it "phase stubs are no-ops by default" do
      expect { base_class.new.send(:_test_phase_inputs!) }.not_to raise_error
    end

    it "orchestrator passes kwargs to phases" do
      received_kwargs = {}
      rk = received_kwargs

      inputs_mod = Module.new do
        define_method(:_test_phase_inputs!) do |**kwargs|
          rk.merge!(kwargs)
        end
      end

      mtx = Stroma::Matrix.define(:test) do
        register :inputs, inputs_mod
      end

      klass = Class.new { include mtx.dsl }
      klass.new.send(:_test_phases_perform!, foo: :bar)

      expect(received_kwargs).to eq(foo: :bar)
    end
  end

  describe "inheritance" do
    let(:extension_module) do
      Module.new do
        const_set(:ClassMethods, Module.new {
          def extension_method
            :extension_result
          end
        })
      end
    end

    let(:base_class) do
      mtx = matrix
      ext = extension_module
      Class.new do
        include mtx.dsl

        extensions do
          wrap :inputs, ext
        end
      end
    end

    let(:child_class) { Class.new(base_class) }

    it "applies wraps to child class" do
      tower = child_class.ancestors.find { |a| a.inspect.include?("Stroma::Tower") }
      expect(tower).not_to be_nil
    end

    it "child has extension ClassMethods", :aggregate_failures do
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

  describe "inheritance isolation" do
    let(:extension_module) { Module.new }

    let(:parent_class) do
      mtx = matrix
      ext = extension_module
      Class.new do
        include mtx.dsl

        extensions do
          wrap :inputs, ext
        end
      end
    end

    let(:child_class) { Class.new(parent_class) }

    it "child modifications do not affect parent", :aggregate_failures do
      child_extension = Module.new

      child_class.class_eval do
        extensions do
          wrap :outputs, child_extension
        end
      end

      expect(parent_class.stroma.hooks.for(:outputs)).to be_empty
      expect(child_class.stroma.hooks.for(:outputs)).not_to be_empty
    end

    it "child inherits parent hooks", :aggregate_failures do
      expect(child_class.stroma.hooks.for(:inputs).size).to eq(1)

      tower = child_class.ancestors.find { |a| a.inspect.include?("Stroma::Tower") }
      expect(tower).not_to be_nil
    end

    it "parent modifications after child creation do not affect child" do
      child_before_count = child_class.stroma.hooks.for(:outputs).size
      new_extension = Module.new

      parent_class.class_eval do
        extensions do
          wrap :outputs, new_extension
        end
      end

      expect(child_class.stroma.hooks.for(:outputs).size).to eq(child_before_count)
    end
  end
end
