# frozen_string_literal: true

module Stroma
  # Main entry point for libraries using Stroma.
  #
  # Creates an isolated registry and generates a scoped DSL module.
  # Each matrix has its own registry - no conflicts with other libraries.
  #
  # ## Lifecycle
  #
  # 1. Boot time: Matrix.new creates Registry, registers extensions
  # 2. Boot time: finalize! freezes registry, freeze freezes Matrix
  # 3. Boot time: First include calls dsl, which generates and caches Module
  # 4. Runtime: All structures frozen, no allocations
  #
  # @example
  #   module MyLib
  #     STROMA = Stroma::Matrix.new(:my_lib) do
  #       register :inputs, Inputs::DSL
  #       register :outputs, Outputs::DSL
  #     end
  #     private_constant :STROMA
  #   end
  #
  #   class MyLib::Base
  #     include MyLib::STROMA.dsl
  #   end
  class Matrix
    attr_reader :name, :registry

    def initialize(name, &block)
      @name = name.to_sym
      @registry = Registry.new(@name)
      @dsl_module = nil

      instance_eval(&block) if block_given?
      @registry.finalize!
      dsl # Eager generation before freeze
      freeze
    end

    def register(key, extension)
      @registry.register(key, extension)
    end

    def dsl
      @dsl_module ||= DSL::Generator.call(self)
    end

    def entries
      registry.entries
    end

    def keys
      registry.keys
    end

    def key?(key)
      registry.key?(key)
    end
  end
end
