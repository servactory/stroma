# frozen_string_literal: true

module Stroma
  # Manages registration of DSL modules for a specific matrix.
  #
  # ## Purpose
  #
  # Stores DSL module entries with their keys.
  # Implements two-phase lifecycle: registration → finalization.
  # Each Matrix has its own Registry - no global state.
  #
  # ## Usage
  #
  # ```ruby
  # registry = Stroma::Registry.new(:my_lib)
  # registry.register(:inputs, Inputs::DSL)
  # registry.register(:outputs, Outputs::DSL)
  # registry.finalize!
  #
  # registry.keys      # => [:inputs, :outputs]
  # registry.key?(:inputs)  # => true
  # ```
  #
  # ## Integration
  #
  # Created and owned by Matrix.
  # Entries are accessed via Matrix#entries and Matrix#keys.
  class Registry
    # @!attribute [r] matrix_name
    #   @return [Symbol] The name of the owning matrix
    attr_reader :matrix_name

    # Creates a new registry for the given matrix.
    #
    # @param matrix_name [Symbol, String] The matrix identifier
    def initialize(matrix_name)
      @matrix_name = matrix_name.to_sym
      @entries = []
      @finalized = false
    end

    # Registers a DSL module with the given key.
    #
    # @param key [Symbol, String] The registry key
    # @param extension [Module] The DSL module to register
    # @raise [Exceptions::RegistryFrozen] If registry is finalized
    # @raise [Exceptions::KeyAlreadyRegistered] If key already exists
    # @return [void]
    def register(key, extension)
      if @finalized
        raise Exceptions::RegistryFrozen,
              "Registry for #{@matrix_name.inspect} is finalized"
      end

      key = key.to_sym
      if @entries.any? { |e| e.key == key }
        raise Exceptions::KeyAlreadyRegistered,
              "Key #{key.inspect} already registered in #{@matrix_name.inspect}"
      end

      @entries << Entry.new(key:, extension:)
    end

    # Finalizes the registry, preventing further registrations.
    #
    # Idempotent - can be called multiple times safely.
    #
    # @return [void]
    def finalize!
      return if @finalized

      @entries.freeze
      @finalized = true
    end

    # Returns all registered entries.
    #
    # @raise [Exceptions::RegistryNotFinalized] If not finalized
    # @return [Array<Entry>] The registry entries
    def entries
      ensure_finalized!
      @entries
    end

    # Returns all registered keys.
    #
    # @raise [Exceptions::RegistryNotFinalized] If not finalized
    # @return [Array<Symbol>] The registry keys
    def keys
      ensure_finalized!
      @entries.map(&:key)
    end

    # Checks if a key is registered.
    #
    # @param key [Symbol, String] The key to check
    # @raise [Exceptions::RegistryNotFinalized] If not finalized
    # @return [Boolean] true if the key is registered
    def key?(key)
      ensure_finalized!
      @entries.any? { |e| e.key == key.to_sym }
    end

    private

    # Ensures the registry is finalized.
    #
    # @raise [Exceptions::RegistryNotFinalized] If not finalized
    # @return [void]
    def ensure_finalized!
      return if @finalized

      raise Exceptions::RegistryNotFinalized,
            "Registry for #{@matrix_name.inspect} not finalized"
    end
  end
end
