# frozen_string_literal: true

module Stroma
  module Hooks
    # Applies registered wraps to a target class via per-entry towers.
    #
    # ## Purpose
    #
    # For each entry with wraps, builds a tower module that contains
    # all wrap extensions. Towers are prepended to the target class.
    # ClassMethods from wrap extensions are extended directly.
    #
    # ## Tower convention
    #
    # Wrap extensions follow the ClassMethods/InstanceMethods convention:
    # - `ClassMethods` — extended directly on target_class (for DSL methods)
    # - `InstanceMethods` — included in tower module, prepended on target_class
    # - Phase::Resolver — checked first for generic wrappable extensions
    # - Plain module (no nested constants) — included in tower as-is
    #
    # ## Caching
    #
    # Towers are cached by [matrix_name, entry_key, extensions]
    # since they are built at boot time and reused across subclasses.
    #
    # ## Usage
    #
    # ```ruby
    # # Called internally during class inheritance
    # Stroma::Hooks::Applier.apply!(ChildService, hooks, matrix)
    # ```
    #
    # ## Integration
    #
    # Called by DSL::Generator's inherited hook.
    class Applier
      class << self
        # Applies all registered wraps to the target class.
        #
        # @param target_class [Class] The class to apply wraps to
        # @param hooks [Collection] The hooks collection to apply
        # @param matrix [Matrix] The matrix providing registry entries
        # @return [void]
        def apply!(target_class, hooks, matrix)
          new(target_class, hooks, matrix).apply!
        end

        # Fetches a cached tower or builds a new one via the given block.
        #
        # Thread-safety note: tower building occurs during class body evaluation
        # (inherited hook), which is single-threaded in standard Ruby boot.
        # No synchronization is needed for boot-time-only usage.
        #
        # @param cache_key [Array] The cache key
        # @yield Block that builds the tower when not cached
        # @return [Module] The tower module
        def fetch_or_build_tower(cache_key)
          tower_cache[cache_key] ||= yield
        end

        # Clears the tower cache. Intended for test cleanup.
        #
        # @return [void]
        def reset_tower_cache!
          @tower_cache = {}
        end

        private

        # Returns the tower cache, lazily initialized.
        #
        # @return [Hash] The cache mapping [matrix_name, key, extensions] to tower modules
        def tower_cache
          @tower_cache ||= {}
        end
      end

      # Creates a new applier for applying wraps to a class.
      #
      # @param target_class [Class] The class to apply wraps to
      # @param hooks [Collection] The hooks collection to apply
      # @param matrix [Matrix] The matrix providing registry entries
      def initialize(target_class, hooks, matrix)
        @target_class = target_class
        @hooks = hooks
        @matrix = matrix
      end

      # Applies all registered wraps to the target class.
      #
      # For each entry with wraps:
      # - Extends ClassMethods directly on target class
      # - Builds/fetches a tower module and prepends it
      #
      # @return [void]
      def apply! # rubocop:disable Metrics/MethodLength
        return if @hooks.empty?

        @matrix.entries.each do |entry|
          wraps_for_entry = @hooks.for(entry.key)
          next if wraps_for_entry.empty?

          wraps_for_entry.each do |wrap|
            ext = wrap.extension
            @target_class.extend(ext::ClassMethods) if ext.const_defined?(:ClassMethods, false)
          end

          tower = resolve_tower(entry, wraps_for_entry)
          @target_class.prepend(tower)
        end
      end

      private

      # Fetches a cached tower or builds a new one.
      #
      # @param entry [Entry] The entry to build tower for
      # @param wraps [Array<Wrap>] The wraps for this entry
      # @return [Module] The tower module
      def resolve_tower(entry, wraps)
        cache_key = [entry.matrix_name, entry.key, wraps.map(&:extension)]
        self.class.fetch_or_build_tower(cache_key) { build_tower(entry, wraps) }
      end

      # Builds a tower module from wraps for a specific entry.
      #
      # @param entry [Entry] The entry to build tower for
      # @param wraps [Array<Wrap>] The wraps for this entry
      # @return [Module] The tower module
      def build_tower(entry, wraps) # rubocop:disable Metrics/MethodLength
        tower = Module.new do
          wraps.reverse_each do |wrap|
            ext = wrap.extension
            resolved = Phase::Resolver.resolve(ext, entry)
            if resolved
              include resolved
            elsif ext.const_defined?(:InstanceMethods, false)
              include ext::InstanceMethods
            else
              include ext
            end
          end
        end
        Utils.name_module(tower, "Stroma::Tower(#{entry.matrix_name}:#{entry.key})")
        tower
      end
    end
  end
end
