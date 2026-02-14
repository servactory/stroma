# frozen_string_literal: true

module Stroma
  module Hooks
    # DSL interface for registering wraps in extensions block.
    #
    # ## Purpose
    #
    # Provides wrap DSL method for hook registration.
    # Validates target keys against the matrix's registry.
    # Delegates to Hooks::Collection for storage.
    #
    # ## Usage
    #
    # ```ruby
    # class MyService < MyLib::Base
    #   extensions do
    #     wrap :actions, ValidationModule, AuthModule
    #   end
    # end
    # ```
    #
    # ## Integration
    #
    # Created by DSL::Generator's extensions method.
    # Cached as @stroma_hooks_factory on each service class.
    class Factory
      # Creates a new factory for registering wraps.
      #
      # @param hooks [Collection] The hooks collection to add to
      # @param matrix [Matrix] The matrix providing valid keys
      def initialize(hooks, matrix)
        @hooks = hooks
        @matrix = matrix
      end

      # Registers one or more wraps for a target key.
      #
      # @param key [Symbol] The registry key to wrap
      # @param extensions [Array<Module>] Extension modules to include
      # @raise [Exceptions::UnknownHookTarget] If key is not registered
      # @return [void]
      #
      # @example
      #   wrap :actions, ValidationModule, AuthorizationModule
      def wrap(key, *extensions)
        validate_key!(key)
        extensions.each { |extension| @hooks.add(key, extension) }
      end

      private

      # Validates that the key exists in the matrix's registry.
      #
      # @param key [Symbol] The key to validate
      # @raise [Exceptions::UnknownHookTarget] If key is not registered
      # @return [void]
      def validate_key!(key)
        return if @matrix.key?(key)

        raise Exceptions::UnknownHookTarget,
              "Unknown hook target #{key.inspect} for #{@matrix.name.inspect}. " \
              "Valid: #{@matrix.keys.map(&:inspect).join(', ')}"
      end
    end
  end
end
