# frozen_string_literal: true

module Stroma
  # Manages registration of DSL modules for a specific matrix.
  #
  # Each Matrix instance has its own Registry - no global state.
  # Implements two-phase lifecycle: registration → finalization.
  #
  # @example
  #   registry = Stroma::Registry.new(:my_lib)
  #   registry.register(:inputs, Inputs::DSL)
  #   registry.finalize!
  #   registry.keys  # => [:inputs]
  class Registry
    attr_reader :matrix_name

    def initialize(matrix_name)
      @matrix_name = matrix_name.to_sym
      @entries = []
      @finalized = false
    end

    def register(key, extension)
      raise Exceptions::RegistryFrozen,
            "Registry for #{@matrix_name.inspect} is finalized" if @finalized

      key = key.to_sym
      if @entries.any? { |e| e.key == key }
        raise Exceptions::KeyAlreadyRegistered,
              "Key #{key.inspect} already registered in #{@matrix_name.inspect}"
      end

      @entries << Entry.new(key:, extension:)
    end

    def finalize!
      return if @finalized

      @entries.freeze
      @finalized = true
    end

    def entries
      ensure_finalized!
      @entries
    end

    def keys
      ensure_finalized!
      @entries.map(&:key)
    end

    def key?(key)
      ensure_finalized!
      @entries.any? { |e| e.key == key.to_sym }
    end

    private

    def ensure_finalized!
      return if @finalized

      raise Exceptions::RegistryNotFinalized,
            "Registry for #{@matrix_name.inspect} not finalized"
    end
  end
end
