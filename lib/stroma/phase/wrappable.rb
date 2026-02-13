# frozen_string_literal: true

module Stroma
  module Phase
    # Extend-module for generic extensions that wrap phase methods.
    #
    # ## Purpose
    #
    # Provides `wrap_phase` DSL for extensions that need to wrap
    # specific phase methods with custom logic. The wraps are
    # resolved at tower-build time by Phase::Resolver.
    #
    # ## Usage
    #
    # ```ruby
    # module MyExtension
    #   extend Stroma::Phase::Wrappable
    #
    #   wrap_phase(:actions) do |phase, **kwargs|
    #     # before logic
    #     phase.call(**kwargs)
    #     # after logic
    #   end
    # end
    # ```
    module Wrappable
      # Registers a phase wrap for the given entry key.
      #
      # @param key [Symbol] The entry key to wrap
      # @yield [phase, **kwargs] Block that wraps the phase method
      # @yieldparam phase [Method] The original phase method (call via phase.call)
      # @return [void]
      def wrap_phase(key, &block)
        stroma_phase_wraps << Wrap.new(target_key: key, block: block)
      end

      # Returns all registered phase wraps for this extension.
      #
      # @return [Array<Phase::Wrap>] The registered wraps
      def stroma_phase_wraps
        @stroma_phase_wraps ||= []
      end
    end
  end
end
