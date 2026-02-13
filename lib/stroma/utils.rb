# frozen_string_literal: true

module Stroma
  # Shared utility methods for the Stroma framework.
  #
  # ## Purpose
  #
  # Provides common helper methods used across multiple Stroma components.
  # All methods are module functions - callable as both module methods
  # and instance methods when included.
  module Utils
    module_function

    # Assigns a descriptive label to an anonymous module for debugging.
    # Uses set_temporary_name (Ruby 3.3+) when available.
    #
    # TODO: Remove the else branch when Ruby 3.2 support is dropped.
    #       The define_singleton_method fallback is a temporary workaround
    #       that only affects #inspect and #to_s. Unlike set_temporary_name,
    #       it does not set #name, so the module remains technically anonymous.
    #
    # @param mod [Module] The module to label
    # @param label [String] The descriptive label
    # @return [void]
    def label_module(mod, label)
      if mod.respond_to?(:set_temporary_name)
        mod.set_temporary_name(label)
      else
        mod.define_singleton_method(:inspect) { label }
        mod.define_singleton_method(:to_s) { label }
      end
    end
  end
end
