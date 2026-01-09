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
    return if Stroma::Registry.instance.instance_variable_get(:@finalized)

    MOCK_MODULES.each do |key, mod|
      Stroma::Registry.register(key, mod)
    end
    Stroma::Registry.finalize!
  end
end
