# frozen_string_literal: true

module Stroma
  module DSL
    # Generates a DSL module scoped to a specific Matrix.
    #
    # ## Design
    #
    # The generated module:
    # - Stores matrix reference on the module itself (via @stroma_matrix)
    # - Uses ClassMethods module defined via const_set
    # - Properly handles inheritance with state duplication
    #
    # ## Memory Model
    #
    # ```
    # Matrix (frozen)
    #   └── @dsl_module (generated Module, cached)
    #         ├── @stroma_matrix → Matrix
    #         └── ClassMethods module
    #
    # ServiceClass (includes dsl)
    #   ├── @stroma_matrix → Matrix (same reference)
    #   └── @stroma → State (unique per class)
    #         ├── hooks → Collection (deep copied on inherit)
    #         └── settings → Collection (deep copied on inherit)
    # ```
    #
    # ## Boot vs Runtime
    #
    # Boot time (one-time):
    # - Generator.call creates Module.new
    # - ClassMethods module defined inside via const_set
    # - First include sets up base class
    #
    # Runtime (no allocations):
    # - stroma_matrix returns cached @stroma_matrix
    # - stroma returns cached @stroma
    # - extensions block only called at class definition time
    class Generator
      class << self
        def call(matrix)
          new(matrix).generate
        end
      end

      def initialize(matrix)
        @matrix = matrix
      end

      def generate
        matrix = @matrix
        class_methods = build_class_methods

        Module.new do
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
      end

      private

      def build_class_methods
        Module.new do
          def stroma_matrix
            @stroma_matrix
          end

          def stroma
            @stroma ||= State.new
          end

          def inherited(child)
            super
            child.instance_variable_set(:@stroma_matrix, stroma_matrix)
            child.instance_variable_set(:@stroma, stroma.dup)
            Hooks::Applier.new(child, child.stroma.hooks, stroma_matrix).apply!
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
