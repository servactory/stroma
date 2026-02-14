# frozen_string_literal: true

RSpec.describe Stroma::Phase::Resolver do
  let(:entry) { Stroma::Entry.new(key: :actions, extension: Module.new, matrix_name: :test) }

  describe ".resolve" do
    context "when extension does not respond to stroma_phase_wraps" do
      let(:extension) { Module.new }

      it "returns nil" do
        expect(described_class.resolve(extension, entry)).to be_nil
      end
    end

    context "when extension has no wraps for the entry" do
      let(:extension) do
        Module.new do
          extend Stroma::Phase::Wrappable

          wrap_phase(:inputs) { |phase, **kwargs| phase.call(**kwargs) }
        end
      end

      it "returns nil" do
        expect(described_class.resolve(extension, entry)).to be_nil
      end
    end

    context "when extension has wraps for the entry" do
      let(:call_log) { [] }

      let(:extension) do
        log = call_log
        Module.new do
          extend Stroma::Phase::Wrappable

          wrap_phase(:actions) do |phase, **kwargs|
            log << :before
            phase.call(**kwargs)
            log << :after
          end
        end
      end

      let(:resolved) { described_class.resolve(extension, entry) }

      it "returns a module" do
        expect(resolved).to be_a(Module)
      end

      it "labels the module" do
        expect(resolved.inspect).to include("Stroma::Phase::Resolved(test:actions)")
      end

      it "defines the phase method" do
        expect(resolved.instance_methods(false)).to include(:_test_phase_actions!)
      end

      it "executes the wrap block around the phase" do
        target_class = Class.new do
          define_method(:_test_phase_actions!) { |**| } # rubocop:disable Lint/EmptyBlock
        end
        target_class.prepend(resolved)

        target_class.new.send(:_test_phase_actions!)
        expect(call_log).to eq(%i[before after])
      end
    end

    context "when multiple resolved modules are combined in a tower" do
      let(:call_log) { [] }

      let(:first_extension) do
        log = call_log
        Module.new do
          extend Stroma::Phase::Wrappable

          wrap_phase(:actions) do |phase, **kwargs|
            log << :first_before
            phase.call(**kwargs)
            log << :first_after
          end
        end
      end

      let(:second_extension) do
        log = call_log
        Module.new do
          extend Stroma::Phase::Wrappable

          wrap_phase(:actions) do |phase, **kwargs|
            log << :second_before
            phase.call(**kwargs)
            log << :second_after
          end
        end
      end

      let(:tower) do
        first_resolved = described_class.resolve(first_extension, entry)
        second_resolved = described_class.resolve(second_extension, entry)
        Module.new do
          include second_resolved
          include first_resolved
        end
      end

      it "chains correctly without infinite recursion" do
        target_class = Class.new do
          define_method(:_test_phase_actions!) { |**| } # rubocop:disable Lint/EmptyBlock
        end
        target_class.prepend(tower)

        target_class.new.send(:_test_phase_actions!)
        expect(call_log).to eq(%i[first_before second_before second_after first_after])
      end
    end

    context "when multiple wraps target the same key (last-wins)" do
      let(:call_log) { [] }

      let(:extension) do
        log = call_log
        Module.new do
          extend Stroma::Phase::Wrappable

          wrap_phase(:actions) do |phase, **kwargs|
            log << :first
            phase.call(**kwargs)
          end

          wrap_phase(:actions) do |phase, **kwargs|
            log << :second
            phase.call(**kwargs)
          end
        end
      end

      let(:resolved) { described_class.resolve(extension, entry) }

      it "only executes the last wrap block" do
        target_class = Class.new do
          define_method(:_test_phase_actions!) { |**| } # rubocop:disable Lint/EmptyBlock
        end
        target_class.prepend(resolved)

        target_class.new.send(:_test_phase_actions!)
        expect(call_log).to eq(%i[second])
      end
    end
  end
end
