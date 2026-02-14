# frozen_string_literal: true

RSpec.describe Stroma::VERSION do
  it { expect(Stroma::VERSION::STRING).not_to be_nil }
end
