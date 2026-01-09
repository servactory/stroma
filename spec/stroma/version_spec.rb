# frozen_string_literal: true

RSpec.describe Stroma::VERSION do
  it { expect(Stroma::VERSION::STRING).to be_present }
end
