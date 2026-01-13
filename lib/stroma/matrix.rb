# frozen_string_literal: true

module Stroma
  # Main entry point for libraries using Stroma.
  #
  # ## Purpose
  #
  # Creates an isolated registry and generates a scoped DSL module.
  # Each matrix has its own registry - no conflicts with other libraries.
  #
  # Lifecycle:
  # - Boot time: Matrix.new creates Registry, registers extensions
  # - Boot time: finalize! freezes registry, dsl generates Module
  # - Boot time: freeze makes Matrix immutable
  # - Runtime: All structures frozen, no allocations
  #
  # ## Usage
  #
  # ```ruby
  # module MyLib
  #   STROMA = Stroma::Matrix.new(:my_lib) do
  #     register :inputs, Inputs::DSL
  #     register :outputs, Outputs::DSL
  #   end
  #   private_constant :STROMA
  # end
  #
  # class MyLib::Base
  #   include MyLib::STROMA.dsl
  # end
  # ```
  #
  # ## Integration
  #
  # Stored as a constant in the library's namespace.
  # Owns the Registry and generates DSL module via DSL::Generator.
  class Matrix
    # @!attribute [r] name
    #   @return [Symbol] The matrix identifier
    # @!attribute [r] registry
    #   @return [Registry] The registry of DSL modules
    attr_reader :name, :registry

    # Creates a new Matrix with given name.
    #
    # Evaluates the block to register DSL modules, then finalizes
    # the registry and freezes the matrix.
    #
    # @param name [Symbol, String] The matrix identifier
    # @yield Block for registering DSL modules
    def initialize(name, &block)
      @name = name.to_sym
      @registry = Registry.new(@name)
      @dsl_module = nil

      instance_eval(&block) if block_given?
      @registry.finalize!
      dsl # Eager generation before freeze
      freeze
    end

    # Registers a DSL module with the given key.
    #
    # @param key [Symbol] The registry key
    # @param extension [Module] The DSL module to register
    # @return [void]
    def register(key, extension)
      @registry.register(key, extension)
    end

    # Returns the generated DSL module.
    #
    # Creates and caches the module on first call.
    #
    # @return [Module] The DSL module to include in base classes
    def dsl
      @dsl_module ||= DSL::Generator.call(self)
    end

    # Returns all registered entries.
    #
    # @return [Array<Entry>] The registry entries
    def entries
      registry.entries
    end

    # Returns all registered keys.
    #
    # @return [Array<Symbol>] The registry keys
    def keys
      registry.keys
    end

    # Checks if a key is registered.
    #
    # @param key [Symbol] The key to check
    # @return [Boolean] true if the key is registered
    def key?(key)
      registry.key?(key)
    end
  end
end
