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
    let(:before_extension) { Module.new }

    before do
      hooks.add(:before, :inputs, before_extension)
    end

    it "applies hooks via class method" do
      described_class.apply!(target_class, hooks, matrix)
      expect(target_class.ancestors).to include(before_extension)
    end
  end

  describe "#apply!" do
    context "when hooks are empty (defer)" do
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

    context "when entries are NOT in ancestors (interleave)" do
      context "with a before hook" do
        let(:before_ext) { Module.new }

        before { hooks.add(:before, :inputs, before_ext) }

        it "positions before hook above entry in MRO" do
          applier.apply!
          ancestors = target_class.ancestors

          expect(ancestors.index(before_ext)).to be < ancestors.index(inputs_dsl)
        end

        it "includes all entries" do
          applier.apply!
          ancestors = target_class.ancestors

          expect(ancestors).to include(inputs_dsl, outputs_dsl)
        end
      end

      context "with an after hook" do
        let(:after_ext) { Module.new }

        before { hooks.add(:after, :inputs, after_ext) }

        it "positions after hook below entry in MRO" do
          applier.apply!
          ancestors = target_class.ancestors

          expect(ancestors.index(after_ext)).to be > ancestors.index(inputs_dsl)
        end
      end

      context "with both before and after hooks" do
        let(:before_ext) { Module.new }
        let(:after_ext) { Module.new }

        before do
          hooks.add(:before, :inputs, before_ext)
          hooks.add(:after, :inputs, after_ext)
        end

        it "positions before above and after below entry", :aggregate_failures do
          applier.apply!
          ancestors = target_class.ancestors

          before_idx = ancestors.index(before_ext)
          entry_idx = ancestors.index(inputs_dsl)
          after_idx = ancestors.index(after_ext)

          expect(before_idx).to be < entry_idx
          expect(after_idx).to be > entry_idx
        end
      end

      context "with multiple before hooks" do
        let(:first_before) { Module.new }
        let(:second_before) { Module.new }

        before do
          hooks.add(:before, :inputs, first_before)
          hooks.add(:before, :inputs, second_before)
        end

        it "first registered is outermost in MRO", :aggregate_failures do
          applier.apply!
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
        end

        it "first registered is closest to entry", :aggregate_failures do
          applier.apply!
          ancestors = target_class.ancestors

          expect(ancestors.index(inputs_dsl)).to be < ancestors.index(first_after)
          expect(ancestors.index(first_after)).to be < ancestors.index(second_after)
        end
      end

      context "with hooks for different entries" do
        let(:before_inputs_ext) { Module.new }
        let(:after_outputs_ext) { Module.new }

        before do
          hooks.add(:before, :inputs, before_inputs_ext)
          hooks.add(:after, :outputs, after_outputs_ext)
        end

        it "each hook is adjacent to its target entry", :aggregate_failures do
          applier.apply!
          ancestors = target_class.ancestors

          expect(ancestors.index(before_inputs_ext)).to be < ancestors.index(inputs_dsl)
          expect(ancestors.index(after_outputs_ext)).to be > ancestors.index(outputs_dsl)
        end
      end
    end

    context "when entries are already in ancestors (hooks only)" do
      let(:before_ext) { Module.new }

      before do
        target_class.include(outputs_dsl)
        target_class.include(inputs_dsl)
        hooks.add(:before, :inputs, before_ext)
      end

      it "includes hook extensions" do
        applier.apply!
        expect(target_class.ancestors).to include(before_ext)
      end

      it "does not duplicate entries in ancestors" do
        count_before = target_class.ancestors.count { |a| a == inputs_dsl }
        applier.apply!
        count_after = target_class.ancestors.count { |a| a == inputs_dsl }

        expect(count_after).to eq(count_before)
      end
    end
  end

  describe "entries_in_ancestors? (private)" do
    it "returns false when entries not in ancestors" do
      expect(applier.send(:entries_in_ancestors?)).to be false
    end

    it "returns true when an entry is in ancestors" do
      target_class.include(inputs_dsl)
      expect(applier.send(:entries_in_ancestors?)).to be true
    end
  end
end
