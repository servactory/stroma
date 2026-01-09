# frozen_string_literal: true

require "zeitwerk"

require "active_support/all"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/stroma/test_kit/rspec")
loader.inflector.inflect(
  "dsl" => "DSL"
)
loader.setup

module Stroma; end

require "stroma/engine" if defined?(Rails::Engine)
