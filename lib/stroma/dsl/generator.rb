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
    # ## Deferred Entry Inclusion
    #
    # Entry extensions are NOT included via `Module#include` at the base class level.
    # Instead, only the `self.included` callback is fired (via `send(:included, base)`)
    # to set up ClassMethods, constants, etc. The actual module insertion into the
    # ancestor chain (`append_features`) is deferred until {Hooks::Applier} interleaves
    # entries with hooks in child classes.
    #
    # **Contract:** Entry extensions MUST implement `self.included` as idempotent.
    # The callback fires twice per entry per class hierarchy:
    # 1. At base class creation (deferred, via `send(:included, base)`)
    # 2. At child class creation (real, via `include` in {Hooks::Applier})
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

              # Deferred inclusion: triggers `included` callback without `append_features`.
              # The callback runs ClassMethods/Workspace setup on base.
              # `append_features` (actual module insertion into ancestors) is deferred
              # until Applier interleaves entries with hooks in child classes.
              # NOTE: `included` will fire again when Applier calls `include` on child,
              # so entry extensions must design `self.included` as idempotent.
              mtx.entries.each { |entry| entry.extension.send(:included, base) }
            end
          end

          const_set(:ClassMethods, class_methods)
        end

        Utils.name_module(mod, "Stroma::DSL(#{matrix.name})")
        Utils.name_module(class_methods, "Stroma::DSL(#{matrix.name})::ClassMethods")

        mod
      end

      private

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
