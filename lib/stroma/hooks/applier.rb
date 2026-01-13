# frozen_string_literal: true

module Stroma
  module Hooks
    # Applies registered hooks to a target class.
    #
    # Uses the matrix's registry entries to determine hook order.
    #
    # @example
    #   applier = Applier.new(ChildService, hooks, matrix)
    #   applier.apply!
    class Applier
      # Creates a new applier for applying hooks to a class.
      #
      # @param target_class [Class] The class to apply hooks to
      # @param hooks [Collection] The hooks collection to apply
      # @param matrix [Matrix] The matrix providing registry entries
      def initialize(target_class, hooks, matrix)
        @target_class = target_class
        @hooks = hooks
        @matrix = matrix
      end

      # Applies all registered hooks to the target class.
      #
      # For each registry entry, includes before hooks first,
      # then after hooks. Does nothing if hooks collection is empty.
      #
      # @return [void]
      def apply!
        return if @hooks.empty?

        @matrix.entries.each do |entry|
          @hooks.before(entry.key).each { |hook| @target_class.include(hook.extension) }
          @hooks.after(entry.key).each { |hook| @target_class.include(hook.extension) }
        end
      end
    end
  end
end
