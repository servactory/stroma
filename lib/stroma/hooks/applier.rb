# frozen_string_literal: true

module Stroma
  module Hooks
    # Applies registered hooks to a target class with deferred entry inclusion.
    #
    # ## Purpose
    #
    # Manages hook and entry module inclusion into the target class.
    # Operates in three modes depending on current state:
    # - No hooks: returns immediately (entries stay deferred)
    # - Entries already in ancestors: includes only new hooks
    # - Entries not in ancestors: interleaves entries with hooks for correct MRO
    #
    # ## Usage
    #
    # ```ruby
    # # Called internally during class inheritance
    # applier = Stroma::Hooks::Applier.new(ChildService, hooks, matrix)
    # applier.apply!
    # ```
    #
    # ## Integration
    #
    # Called by DSL::Generator's inherited hook.
    # Creates a temporary instance that is garbage collected after apply!.
    class Applier
      class << self
        # Applies all registered hooks to the target class.
        #
        # Convenience class method that creates an applier and applies hooks.
        #
        # @param target_class [Class] The class to apply hooks to
        # @param hooks [Collection] The hooks collection to apply
        # @param matrix [Matrix] The matrix providing registry entries
        # @return [void]
        def apply!(target_class, hooks, matrix)
          new(target_class, hooks, matrix).apply!
        end
      end

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
      # Three modes based on current state:
      # - No hooks: return immediately (defer entry inclusion)
      # - Entries already in ancestors: include only hooks
      # - Entries not in ancestors: interleave entries with hooks
      #
      # @return [void]
      def apply!
        return if @hooks.empty?

        if entries_in_ancestors?
          include_hooks_only
        else
          include_entries_with_hooks
        end
      end

      private

      # Checks whether all entry extensions are already in the target class ancestors.
      #
      # Uses all? so that partial inclusion (some entries present, some not)
      # falls through to include_entries_with_hooks where Ruby skips
      # already-included modules (idempotent) and interleaves the rest.
      #
      # @return [Boolean]
      def entries_in_ancestors?
        ancestors = @target_class.ancestors
        @matrix.entries.all? { |e| ancestors.include?(e.extension) }
      end

      # Includes entries interleaved with their hooks.
      #
      # For each entry: after hooks first (reversed), then entry, then before hooks (reversed).
      # reverse_each ensures first registered = outermost in MRO.
      #
      # @return [void]
      def include_entries_with_hooks
        @matrix.entries.each do |entry|
          @hooks.after(entry.key).reverse_each { |hook| @target_class.include(hook.extension) }
          @target_class.include(entry.extension)
          @hooks.before(entry.key).reverse_each { |hook| @target_class.include(hook.extension) }
        end
      end

      # Includes only hook extensions without entries.
      #
      # Used when entries are already in ancestors (multi-level inheritance).
      #
      # @return [void]
      def include_hooks_only
        @matrix.entries.each do |entry|
          @hooks.before(entry.key).reverse_each { |hook| @target_class.include(hook.extension) }
          @hooks.after(entry.key).reverse_each { |hook| @target_class.include(hook.extension) }
        end
      end
    end
  end
end
