# frozen_string_literal: true

module Stroma
  module DSL
    # Generates a DSL module scoped to a specific Matrix.
    #
    # ## Purpose
    #
    # Creates a module that:
    # - Stores matrix reference on the module itself
    # - Defines ClassMethods for service classes
    # - Handles inheritance with state duplication
    #
    # Memory model:
    # - Matrix owns @dsl_module (generated once, cached)
    # - ServiceClass gets @stroma_matrix (same reference)
    # - ServiceClass gets @stroma (unique State per class)
    #
    # ## Usage
    #
    # ```ruby
    # # Called internally by Matrix#dsl
    # dsl_module = Stroma::DSL::Generator.call(matrix)
    #
    # # The generated module is included in base classes
    # class MyLib::Base
    #   include dsl_module
    # end
    # ```
    #
    # ## Integration
    #
    # Called by Matrix#dsl to generate the DSL module.
    # Generated module includes all registered extensions.
    class Generator
      class << self
        # Generates a DSL module for the given matrix.
        #
        # @param matrix [Matrix] The matrix to generate DSL for
        # @return [Module] The generated DSL module
        def call(matrix)
          new(matrix).generate
        end
      end

      # Creates a new generator for the given matrix.
      #
      # @param matrix [Matrix] The matrix to generate DSL for
      def initialize(matrix)
        @matrix = matrix
      end

      # Generates the DSL module.
      #
      # Creates a module with ClassMethods that provides:
      # - stroma_matrix accessor for matrix reference
      # - stroma accessor for per-class state
      # - inherited hook for state duplication
      # - extensions DSL for registering hooks
      #
      # @return [Module] The generated DSL module
      def generate # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        matrix = @matrix
        class_methods = build_class_methods

        mod = Module.new do
          @stroma_matrix = matrix

          class << self
            attr_reader :stroma_matrix

            def included(base)
              mtx = stroma_matrix
              base.extend(self::ClassMethods)
              base.instance_variable_set(:@stroma_matrix, mtx)
              base.instance_variable_set(:@stroma, State.new)

              mtx.entries.each { |entry| base.include(entry.extension) }
            end
          end

          const_set(:ClassMethods, class_methods)
        end

        label_module(mod, "Stroma::DSL(#{matrix.name})")
        label_module(class_methods, "Stroma::DSL(#{matrix.name})::ClassMethods")

        mod
      end

      private

      # Assigns a descriptive label to an anonymous module for debugging.
      # Uses set_temporary_name (Ruby 3.3+) when available.
      #
      # TODO: Remove the else branch when Ruby 3.2 support is dropped.
      #       The define_singleton_method fallback is a temporary workaround
      #       that only affects #inspect and #to_s. Unlike set_temporary_name,
      #       it does not set #name, so the module remains technically anonymous.
      def label_module(mod, label)
        if mod.respond_to?(:set_temporary_name)
          mod.set_temporary_name(label)
        else
          mod.define_singleton_method(:inspect) { label }
          mod.define_singleton_method(:to_s) { label }
        end
      end

      # Builds the ClassMethods module.
      #
      # @return [Module] The ClassMethods module
      def build_class_methods # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        Module.new do
          attr_reader :stroma_matrix

          def stroma
            @stroma ||= State.new
          end

          def inherited(child)
            super
            child.instance_variable_set(:@stroma_matrix, stroma_matrix)
            child.instance_variable_set(:@stroma, stroma.dup)
            Hooks::Applier.apply!(child, child.stroma.hooks, stroma_matrix)
          end

          private

          def extensions(&block)
            @stroma_hooks_factory ||= Hooks::Factory.new(stroma.hooks, stroma_matrix)
            @stroma_hooks_factory.instance_eval(&block)
          end
        end
      end
    end
  end
end
