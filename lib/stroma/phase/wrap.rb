# frozen_string_literal: true

module Stroma
  module Phase
    # Immutable value object representing a generic phase wrap blueprint.
    #
    # ## Purpose
    #
    # Stores a target key and a block that will be used to generate
    # a concrete module wrapping a phase method. Used by extensions
    # that extend Phase::Wrappable.
    #
    # ## Distinction from Hooks::Wrap
    #
    # - `Hooks::Wrap` = concrete binding of a module to an entry (target_key + module)
    # - `Phase::Wrap` = blueprint of a generic wrap with a block (target_key + block)
    #
    # ## Attributes
    #
    # @!attribute [r] target_key
    #   @return [Symbol] Key of the entry to wrap
    # @!attribute [r] block
    #   @return [Proc] Block that wraps the phase method
    Wrap = Data.define(:target_key, :block)
  end
end
