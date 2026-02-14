# frozen_string_literal: true

RSpec.describe Stroma::Utils do
  describe ".name_module" do
    let(:mod) { Module.new }
    let(:name) { "Stroma::Test(example)" }

    before { described_class.name_module(mod, name) }

    it "sets inspect to the name" do
      expect(mod.inspect).to eq(name)
    end

    it "sets to_s to the name" do
      expect(mod.to_s).to eq(name)
    end
  end
end
