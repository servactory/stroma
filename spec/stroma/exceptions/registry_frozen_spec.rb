# frozen_string_literal: true

RSpec.describe Stroma::Exceptions::RegistryFrozen do
  it "inherits from Base" do
    expect(described_class.superclass).to eq(Stroma::Exceptions::Base)
  end

  it "can be rescued as Base" do
    expect { raise described_class }.to raise_error(Stroma::Exceptions::Base)
  end

  it "can be rescued as StandardError" do
    expect { raise described_class }.to raise_error(StandardError)
  end
end
