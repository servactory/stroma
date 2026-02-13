# frozen_string_literal: true

RSpec.describe Stroma::Hooks::Factory do
  let(:hooks) { Stroma::Hooks::Collection.new }
  let(:matrix) do
    Stroma::Matrix.define(:test) do
      register :inputs, Module.new
      register :outputs, Module.new
      register :actions, Module.new
    end
  end
  let(:factory) { described_class.new(hooks, matrix) }
  let(:first_module) { Module.new }
  let(:second_module) { Module.new }

  describe "#wrap" do
    it "adds a wrap", :aggregate_failures do
      factory.wrap(:actions, first_module)
      expect(hooks.for(:actions).size).to eq(1)
      expect(hooks.for(:actions).first.extension).to eq(first_module)
    end

    it "adds multiple modules at once" do
      factory.wrap(:actions, first_module, second_module)
      expect(hooks.for(:actions).size).to eq(2)
    end

    it "raises UnknownHookTarget for unknown key" do
      expect { factory.wrap(:unknown, first_module) }.to raise_error(
        Stroma::Exceptions::UnknownHookTarget,
        "Unknown hook target :unknown for :test. Valid: :inputs, :outputs, :actions"
      )
    end
  end

  describe "valid keys" do
    it "accepts all registered keys" do
      %i[inputs outputs actions].each do |key|
        expect { factory.wrap(key, first_module) }.not_to raise_error
      end
    end
  end
end
