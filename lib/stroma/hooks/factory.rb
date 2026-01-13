# frozen_string_literal: true

module Stroma
  module Hooks
    # DSL interface for registering hooks in extensions block.
    #
    # Validates target keys against the matrix's registry.
    #
    # @example
    #   factory = Factory.new(hooks, matrix)
    #   factory.before(:actions, ValidationModule)
    #   factory.after(:outputs, LoggingModule)
    class Factory
      # Creates a new factory for registering hooks.
      #
      # @param hooks [Collection] The hooks collection to add to
      # @param matrix [Matrix] The matrix providing valid keys
      def initialize(hooks, matrix)
        @hooks = hooks
        @matrix = matrix
      end

      # Registers one or more before hooks for a target key.
      #
      # @param key [Symbol] The registry key to hook before
      # @param extensions [Array<Module>] Extension modules to include
      # @raise [Exceptions::UnknownHookTarget] If key is not registered
      #
      # @example
      #   before :actions, ValidationModule, AuthorizationModule
      def before(key, *extensions)
        validate_key!(key)
        extensions.each { |ext| @hooks.add(:before, key, ext) }
      end

      # Registers one or more after hooks for a target key.
      #
      # @param key [Symbol] The registry key to hook after
      # @param extensions [Array<Module>] Extension modules to include
      # @raise [Exceptions::UnknownHookTarget] If key is not registered
      #
      # @example
      #   after :outputs, LoggingModule, AuditModule
      def after(key, *extensions)
        validate_key!(key)
        extensions.each { |ext| @hooks.add(:after, key, ext) }
      end

      private

      # Validates that the key exists in the matrix's registry.
      #
      # @param key [Symbol] The key to validate
      # @raise [Exceptions::UnknownHookTarget] If key is not registered
      def validate_key!(key)
        return if @matrix.key?(key)

        raise Exceptions::UnknownHookTarget,
              "Unknown hook target #{key.inspect} for #{@matrix.name.inspect}. " \
              "Valid: #{@matrix.keys.map(&:inspect).join(', ')}"
      end
    end
  end
end
