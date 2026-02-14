# frozen_string_literal: true

module Stroma
  module Hooks
    # Immutable value object representing a wrap configuration.
    #
    # ## Purpose
    #
    # Binds an extension module to a specific registry entry key.
    # The extension will be applied as a tower module wrapping
    # the entry's phase method.
    #
    # ## Attributes
    #
    # @!attribute [r] target_key
    #   @return [Symbol] Key of the DSL module to wrap (:inputs, :actions, etc.)
    # @!attribute [r] extension
    #   @return [Module] The module to include in the tower
    #
    # ## Usage
    #
    # ```ruby
    # wrap = Stroma::Hooks::Wrap.new(
    #   target_key: :actions,
    #   extension: MyExtension
    # )
    # ```
    #
    # ## Immutability
    #
    # Wrap is a Data object - frozen and immutable after creation.
    Wrap = Data.define(:target_key, :extension)
  end
end
