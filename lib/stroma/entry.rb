# frozen_string_literal: true

module Stroma
  # Represents a registered DSL entry in the Stroma registry.
  #
  # ## Purpose
  #
  # Immutable value object that holds information about a DSL module
  # registered in the Stroma system. Each entry has a unique key,
  # references a Module that will be included in service classes,
  # and knows its owning matrix name for phase method generation.
  #
  # ## Attributes
  #
  # - `key` (Symbol): Unique identifier for the DSL module (:inputs, :outputs, :actions)
  # - `extension` (Module): The actual DSL module to be included
  # - `matrix_name` (Symbol): Name of the owning matrix
  #
  # ## Usage
  #
  # Entries are created internally by Registry.register:
  #
  # ```ruby
  # registry = Stroma::Registry.new(:my_lib)
  # registry.register(:inputs, MyInputsDSL)
  # # Creates: Entry.new(key: :inputs, extension: MyInputsDSL, matrix_name: :my_lib)
  # ```
  #
  # ## Immutability
  #
  # Entry is immutable (Data object) - once created, it cannot be modified.
  Entry = Data.define(:key, :extension, :matrix_name) do
    # Returns the phase method name for this entry.
    #
    # Computed from matrix_name and key. Used by the orchestrator
    # to call each entry's phase in sequence.
    #
    # @return [Symbol] The phase method name (e.g., :_my_lib_phase_inputs!)
    def phase_method
      :"_#{matrix_name}_phase_#{key}!"
    end
  end
end
