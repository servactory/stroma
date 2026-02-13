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
      let(:log) { call_log }

      let(:extension) do
        l = log
        Module.new do
          extend Stroma::Phase::Wrappable
          wrap_phase(:actions) do |phase, **kwargs|
            l << :before
            phase.call(**kwargs)
            l << :after
          end
        end
      end

      it "returns a module" do
        result = described_class.resolve(extension, entry)
        expect(result).to be_a(Module)
      end

      it "labels the module" do
        result = described_class.resolve(extension, entry)
        expect(result.inspect).to include("Stroma::Phase::Resolved(test:actions)")
      end

      it "defines the phase method" do
        result = described_class.resolve(extension, entry)
        expect(result.instance_methods(false)).to include(:_test_phase_actions!)
      end
    end
  end
end
