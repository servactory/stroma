# frozen_string_literal: true

RSpec.describe Stroma::Hooks::Applier do
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

  let(:hooks) { Stroma::Hooks::Collection.new }
  let(:target_class) { Class.new }
  let(:applier) { described_class.new(target_class, hooks, matrix) }

  def find_tower(target)
    target.ancestors.find { |a| a.inspect.include?("Stroma::Tower") }
  end

  describe ".apply!" do
    let(:wrap_extension) { Module.new }

    before do
      hooks.add(:inputs, wrap_extension)
    end

    it "applies wraps via class method" do
      described_class.apply!(target_class, hooks, matrix)
      expect(target_class.ancestors).to include(wrap_extension)
    end
  end

  describe "#apply!" do
    it "does nothing when hooks empty" do
      ancestors_before = target_class.ancestors.dup
      applier.apply!
      expect(target_class.ancestors).to eq(ancestors_before)
    end

    context "with plain module wraps" do
      let(:wrap_extension) { Module.new }

      before do
        hooks.add(:inputs, wrap_extension)
      end

      it "prepends tower containing the extension" do
        applier.apply!
        expect(target_class.ancestors).to include(wrap_extension)
      end
    end

    context "with ClassMethods convention" do
      let(:class_methods_mod) do
        Module.new do
          def class_dsl_method
            :class_result
          end
        end
      end

      let(:wrap_extension) do
        cm = class_methods_mod
        Module.new do
          const_set(:ClassMethods, cm)
        end
      end

      before do
        hooks.add(:inputs, wrap_extension)
      end

      it "extends ClassMethods on target class" do
        applier.apply!
        expect(target_class).to respond_to(:class_dsl_method)
      end

      it "ClassMethods method works" do
        applier.apply!
        expect(target_class.class_dsl_method).to eq(:class_result)
      end
    end

    context "with InstanceMethods convention" do
      let(:instance_methods_mod) do
        Module.new do
          def instance_wrap_method
            :instance_result
          end
        end
      end

      let(:wrap_extension) do
        im = instance_methods_mod
        Module.new do
          const_set(:InstanceMethods, im)
        end
      end

      before do
        hooks.add(:inputs, wrap_extension)
      end

      it "includes InstanceMethods in tower" do
        applier.apply!
        expect(target_class.new).to respond_to(:instance_wrap_method)
      end
    end

    context "with multiple wraps for same entry" do
      let(:first_extension) { Module.new }
      let(:second_extension) { Module.new }

      before do
        hooks.add(:inputs, first_extension)
        hooks.add(:inputs, second_extension)
      end

      it "applies all wraps", :aggregate_failures do
        applier.apply!
        expect(target_class.ancestors).to include(first_extension)
        expect(target_class.ancestors).to include(second_extension)
      end
    end

    context "with wraps for different entries" do
      let(:inputs_extension) { Module.new }
      let(:outputs_extension) { Module.new }

      before do
        hooks.add(:inputs, inputs_extension)
        hooks.add(:outputs, outputs_extension)
      end

      it "builds separate towers", :aggregate_failures do
        applier.apply!
        expect(target_class.ancestors).to include(inputs_extension)
        expect(target_class.ancestors).to include(outputs_extension)
      end
    end

    describe "tower labeling" do
      let(:wrap_extension) { Module.new }

      before do
        hooks.add(:inputs, wrap_extension)
      end

      it "labels tower modules" do
        applier.apply!
        expect(find_tower(target_class).inspect).to eq("Stroma::Tower(test:inputs)")
      end
    end

    describe "tower caching" do
      let(:wrap_extension) { Module.new }

      before do
        hooks.add(:inputs, wrap_extension)
      end

      it "reuses cached tower for same wraps" do
        first_class = Class.new
        second_class = Class.new

        described_class.apply!(first_class, hooks, matrix)
        described_class.apply!(second_class, hooks, matrix)

        expect(find_tower(first_class)).to equal(find_tower(second_class))
      end

      it "builds different towers for different wraps" do
        other_hooks = Stroma::Hooks::Collection.new
        other_hooks.add(:inputs, Module.new)

        first_class = Class.new
        second_class = Class.new

        described_class.apply!(first_class, hooks, matrix)
        described_class.apply!(second_class, other_hooks, matrix)

        expect(find_tower(first_class)).not_to equal(find_tower(second_class))
      end
    end
  end
end
