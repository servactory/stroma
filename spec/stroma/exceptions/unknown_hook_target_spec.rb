# frozen_string_literal: true

RSpec.describe Stroma::Exceptions::UnknownHookTarget do
  it "inherits from Base" do
    expect(described_class.superclass).to eq(Stroma::Exceptions::Base)
  end

  it "can be rescued as Base" do
    expect { raise described_class }.to raise_error(Stroma::Exceptions::Base)
  end
end
