# frozen_string_literal: true

module Stroma
  module Phase
    # Resolves generic phase wraps into concrete modules.
    #
    # ## Purpose
    #
    # Takes an extension that uses Phase::Wrappable and an entry,
    # finds matching wraps, and generates a module that overrides
    # the phase method with wrap logic.
    #
    # ## Usage
    #
    # ```ruby
    # mod = Stroma::Phase::Resolver.resolve(extension, entry)
    # # => Module with phase method override, or nil
    # ```
    #
    # ## Integration
    #
    # Called by Hooks::Applier during tower building.
    # Returns nil if the extension has no wraps for the given entry.
    class Resolver
      # Resolves an extension's phase wraps for a specific entry.
      #
      # @param extension [Module] The extension (with Phase::Wrappable)
      # @param entry [Entry] The entry to resolve wraps for
      # @return [Module, nil] A module with phase method override, or nil
      def self.resolve(extension, entry) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        return nil unless extension.respond_to?(:stroma_phase_wraps)

        wraps = extension.stroma_phase_wraps.select { |w| w.target_key == entry.key }
        return nil if wraps.empty?

        phase_method = entry.phase_method

        mod = Module.new do
          wraps.each do |wrap|
            blk = wrap.block
            define_method(phase_method) do |**kwargs|
              phase = method(phase_method).super_method
              instance_exec(phase, **kwargs, &blk)
            end
          end
        end

        Utils.name_module(mod, "Stroma::Phase::Resolved(#{entry.matrix_name}:#{entry.key})")
        mod
      end
    end
  end
end
