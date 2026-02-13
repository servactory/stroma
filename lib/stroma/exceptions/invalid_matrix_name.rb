# frozen_string_literal: true

module Stroma
  module Exceptions
    # Raised when a matrix name does not match the valid pattern.
    #
    # ## Purpose
    #
    # Ensures that matrix names are valid Ruby identifiers suitable
    # for use in method names. Names must match /\A[a-z_][a-z0-9_]*\z/.
    #
    # ## Usage
    #
    # ```ruby
    # # This will raise InvalidMatrixName:
    # Stroma::Matrix.define("123invalid") do
    #   register :inputs, MyModule
    # end
    # # => Stroma::Exceptions::InvalidMatrixName:
    # #    Invalid matrix name: "123invalid". Must match /\A[a-z_][a-z0-9_]*\z/
    # ```
    class InvalidMatrixName < Base; end
  end
end
