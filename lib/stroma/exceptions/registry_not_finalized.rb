# frozen_string_literal: true

module Stroma
  module Exceptions
    # Raised when accessing registry before finalization
    #
    # ## Purpose
    #
    # Indicates that the Stroma::Registry was accessed before finalize! was called.
    # The registry must be finalized before it can be used to ensure all DSL modules
    # are registered in the correct order.
    #
    # ## Usage
    #
    # Raised when accessing registry methods before finalization:
    #
    # ```ruby
    # # Before finalize! is called
    # Stroma::Registry.entries
    # # Raises: Stroma::Exceptions::RegistryNotFinalized
    # ```
    #
    # ## Integration
    #
    # This exception typically indicates that Stroma::DSL module was not
    # properly loaded. Ensure stroma gem is properly required before
    # defining service classes.
    class RegistryNotFinalized < Base
    end
  end
end
