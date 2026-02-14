# frozen_string_literal: true

module Stroma
  module Hooks
    # Mutable collection manager for Wrap objects.
    #
    # ## Purpose
    #
    # Stores Wrap objects and provides query methods to retrieve wraps
    # by target key. Supports proper duplication during class
    # inheritance to ensure configuration isolation.
    #
    # ## Usage
    #
    # ```ruby
    # hooks = Stroma::Hooks::Collection.new
    # hooks.add(:actions, MyModule)
    # hooks.add(:actions, AnotherModule)
    #
    # hooks.for(:actions)  # => [Wrap(...)]
    # hooks.empty?         # => false
    # hooks.size           # => 2
    # ```
    #
    # ## Integration
    #
    # Stored in Stroma::State and used by
    # Stroma::Hooks::Applier to apply wraps to classes.
    # Properly duplicated during class inheritance via initialize_dup.
    class Collection
      extend Forwardable

      # @!method each
      #   Iterates over all wraps in the collection.
      #   @yield [Wrap] Each wrap in the collection
      # @!method map
      #   Maps over all wraps in the collection.
      #   @yield [Wrap] Each wrap in the collection
      #   @return [Array] Mapped results
      # @!method size
      #   Returns the number of wraps in the collection.
      #   @return [Integer] Number of wraps
      # @!method empty?
      #   Checks if the collection is empty.
      #   @return [Boolean] true if no wraps registered
      def_delegators :@collection, :each, :map, :size, :empty?

      # Creates a new wraps collection.
      #
      # @param collection [Set] Initial collection of wraps (default: empty Set)
      def initialize(collection = Set.new)
        @collection = collection
      end

      # Creates a deep copy during inheritance.
      #
      # @param original [Collection] The original collection being duplicated
      # @return [void]
      def initialize_dup(original)
        super
        @collection = original.collection.dup
      end

      # Adds a new wrap to the collection.
      #
      # @param target_key [Symbol] Registry key to wrap
      # @param extension [Module] Extension module to include
      # @return [Set] The updated collection
      #
      # Idempotent: duplicate wraps (same target_key + extension) are
      # silently ignored due to Set-based storage with Data.define equality.
      #
      # @example
      #   hooks.add(:actions, ValidationModule)
      def add(target_key, extension)
        @collection << Wrap.new(target_key:, extension:)
      end

      # Returns all wraps for a given key.
      #
      # @param key [Symbol] The target key to filter by
      # @return [Array<Wrap>] Wraps targeting the given key
      #
      # @example
      #   hooks.for(:actions)  # => [Wrap(...)]
      def for(key)
        @collection.select { |wrap| wrap.target_key == key }
      end

      protected

      attr_reader :collection
    end
  end
end
