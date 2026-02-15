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

  describe ".apply!" do
    let(:before_extensionension) { Module.new }

    before do
      hooks.add(:before, :inputs, before_extensionension)
      described_class.apply!(target_class, hooks, matrix)
    end

    it "applies hooks via class method" do
      expect(target_class.ancestors).to include(before_extensionension)
    end
  end

  describe "#apply!" do
    context "when hooks are empty" do
      it "does not modify target class ancestors" do
        ancestors_before = target_class.ancestors.dup
        applier.apply!
        expect(target_class.ancestors).to eq(ancestors_before)
      end

      it "does not include entry extensions", :aggregate_failures do
        applier.apply!
        expect(target_class.ancestors).not_to include(inputs_dsl)
        expect(target_class.ancestors).not_to include(outputs_dsl)
      end
    end

    context "when entries are not in ancestors" do
      context "with a before hook" do
        let(:before_extension) { Module.new }

        before do
          hooks.add(:before, :inputs, before_extension)
          applier.apply!
        end

        it "positions before hook above entry in MRO" do
          ancestors = target_class.ancestors
          expect(ancestors.index(before_extension)).to be < ancestors.index(inputs_dsl)
        end

        it "includes all entries" do
          expect(target_class.ancestors).to include(inputs_dsl, outputs_dsl)
        end
      end

      context "with an after hook" do
        let(:after_extension) { Module.new }

        before do
          hooks.add(:after, :inputs, after_extension)
          applier.apply!
        end

        it "positions after hook below entry in MRO" do
          ancestors = target_class.ancestors
          expect(ancestors.index(after_extension)).to be > ancestors.index(inputs_dsl)
        end
      end

      context "with both before and after hooks" do
        let(:before_extension) { Module.new }
        let(:after_extension) { Module.new }

        before do
          hooks.add(:before, :inputs, before_extension)
          hooks.add(:after, :inputs, after_extension)
          applier.apply!
        end

        it "positions before above and after below entry", :aggregate_failures do
          ancestors = target_class.ancestors
          expect(ancestors.index(before_extension)).to be < ancestors.index(inputs_dsl)
          expect(ancestors.index(after_extension)).to be > ancestors.index(inputs_dsl)
        end
      end

      context "with multiple before hooks" do
        let(:first_before) { Module.new }
        let(:second_before) { Module.new }

        before do
          hooks.add(:before, :inputs, first_before)
          hooks.add(:before, :inputs, second_before)
          applier.apply!
        end

        it "first registered is outermost in MRO", :aggregate_failures do
          ancestors = target_class.ancestors
          expect(ancestors.index(first_before)).to be < ancestors.index(second_before)
          expect(ancestors.index(second_before)).to be < ancestors.index(inputs_dsl)
        end
      end

      context "with multiple after hooks" do
        let(:first_after) { Module.new }
        let(:second_after) { Module.new }

        before do
          hooks.add(:after, :inputs, first_after)
          hooks.add(:after, :inputs, second_after)
          applier.apply!
        end

        it "first registered is closest to entry", :aggregate_failures do
          ancestors = target_class.ancestors
          expect(ancestors.index(inputs_dsl)).to be < ancestors.index(first_after)
          expect(ancestors.index(first_after)).to be < ancestors.index(second_after)
        end
      end

      context "with hooks for different entries" do
        let(:before_inputs_extension) { Module.new }
        let(:after_outputs_extension) { Module.new }

        before do
          hooks.add(:before, :inputs, before_inputs_extension)
          hooks.add(:after, :outputs, after_outputs_extension)
          applier.apply!
        end

        it "each hook is adjacent to its target entry", :aggregate_failures do
          ancestors = target_class.ancestors
          expect(ancestors.index(before_inputs_extension)).to be < ancestors.index(inputs_dsl)
          expect(ancestors.index(after_outputs_extension)).to be > ancestors.index(outputs_dsl)
        end
      end
    end

    context "when entries are already in ancestors" do
      before do
        target_class.include(outputs_dsl)
        target_class.include(inputs_dsl)
      end

      context "with a before hook" do
        let(:before_extension) { Module.new }

        before do
          hooks.add(:before, :inputs, before_extension)
          applier.apply!
        end

        it "includes hook extensions" do
          expect(target_class.ancestors).to include(before_extension)
        end

        it "does not duplicate entries in ancestors" do
          expect(target_class.ancestors.count { |a| a == inputs_dsl }).to eq(1)
        end
      end

      context "with an after hook" do
        let(:after_extension) { Module.new }

        before do
          hooks.add(:after, :inputs, after_extension)
          applier.apply!
        end

        it "includes after hook extensions" do
          expect(target_class.ancestors).to include(after_extension)
        end
      end

      context "with both before and after hooks" do
        let(:before_extension) { Module.new }
        let(:after_extension) { Module.new }

        before do
          hooks.add(:before, :inputs, before_extension)
          hooks.add(:after, :inputs, after_extension)
          applier.apply!
        end

        it "includes both hook types", :aggregate_failures do
          expect(target_class.ancestors).to include(before_extension)
          expect(target_class.ancestors).to include(after_extension)
        end
      end
    end
  end
end
