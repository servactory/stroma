# frozen_string_literal: true

RSpec.describe Stroma::Hooks::Applier do
  let(:inputs_dsl) { Module.new }
  let(:outputs_dsl) { Module.new }
  let(:matrix) do
    inputs = inputs_dsl
    outputs = outputs_dsl
    Stroma::Matrix.new(:test) do
      register :inputs, inputs
      register :outputs, outputs
    end
  end

  let(:hooks) { Stroma::Hooks::Collection.new }
  let(:target_class) { Class.new }
  let(:applier) { described_class.new(target_class, hooks, matrix) }

  describe "#apply!" do
    it "does nothing when hooks empty" do
      applier.apply!
      expect(target_class.ancestors).not_to include(inputs_dsl)
    end

    context "with before hooks" do
      let(:before_extension) { Module.new }

      before do
        hooks.add(:before, :inputs, before_extension)
      end

      it "includes before hook extension" do
        applier.apply!
        expect(target_class.ancestors).to include(before_extension)
      end
    end

    context "with after hooks" do
      let(:after_extension) { Module.new }

      before do
        hooks.add(:after, :outputs, after_extension)
      end

      it "includes after hook extension" do
        applier.apply!
        expect(target_class.ancestors).to include(after_extension)
      end
    end

    context "with multiple hooks" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:before_inputs) { Module.new }
      let(:after_inputs) { Module.new }
      let(:before_outputs) { Module.new }

      before do
        hooks.add(:before, :inputs, before_inputs)
        hooks.add(:after, :inputs, after_inputs)
        hooks.add(:before, :outputs, before_outputs)
      end

      it "applies all hooks", :aggregate_failures do
        applier.apply!
        expect(target_class.ancestors).to include(before_inputs)
        expect(target_class.ancestors).to include(after_inputs)
        expect(target_class.ancestors).to include(before_outputs)
      end
    end
  end
end
