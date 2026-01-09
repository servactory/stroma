# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"
  signature "sig/external"

  check "lib"

  # Enable strict mode for better type safety
  configure_code_diagnostics(D::Ruby.strict)

  # Disable specific diagnostics that don't work well with common Ruby patterns
  configure_code_diagnostics do |config|
    # Mixin modules calling super in methods that will be available after include
    config[D::Ruby::UnexpectedSuper] = :information

    # instance_eval block type mismatch (block doesn't use self argument)
    config[D::Ruby::BlockTypeMismatch] = :information
  end

  # Data.define with block causes Steep type checking issues
  # See: https://github.com/ruby/rbs/blob/master/docs/data_and_struct.md
  ignore "lib/stroma/hooks/hook.rb"

  # Complex splat delegation (*args) in fetch method causes type checking issues
  ignore "lib/stroma/settings/setting.rb"
end
