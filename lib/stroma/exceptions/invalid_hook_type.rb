# frozen_string_literal: true

module Stroma
  module Exceptions
    # Raised when an invalid hook type is provided.
    #
    # ## Purpose
    #
    # Ensures that only valid hook types (:before, :after) are used
    # when creating Stroma::Hooks::Hook objects. Provides fail-fast
    # behavior during class definition rather than silent failures at runtime.
    #
    # ## Usage
    #
    # ```ruby
    # # This will raise InvalidHookType:
    # Stroma::Hooks::Hook.new(
    #   type: :invalid,
    #   target_key: :actions,
    #   extension: MyModule
    # )
    # # => Stroma::Exceptions::InvalidHookType:
    # #    Invalid hook type: :invalid. Valid types: :before, :after
    # ```
    class InvalidHookType < Base; end
  end
end
