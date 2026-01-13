# frozen_string_literal: true

module StromaTestRegistry
  MOCK_MODULES = {
    configuration: Module.new,
    info: Module.new,
    context: Module.new,
    inputs: Module.new,
    internals: Module.new,
    outputs: Module.new,
    actions: Module.new
  }.freeze

  def self.setup!
    # No global setup needed - Matrix is created per-test
  end

  def self.create_matrix(name = :test, keys: MOCK_MODULES.keys)
    modules = MOCK_MODULES
    Stroma::Matrix.new(name) do
      keys.each { |key| register(key, modules[key]) }
    end
  end
end
