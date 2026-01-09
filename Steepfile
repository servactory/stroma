# frozen_string_literal: true

target :lib do
  signature "sig"
  signature "sig/external"

  check "lib"

  # Data.define with block causes Steep type checking issues
  # See: https://github.com/ruby/rbs/blob/master/docs/data_and_struct.md
  ignore "lib/stroma/hooks/hook.rb"

  # Complex splat delegation (*args) in fetch method causes type checking issues
  ignore "lib/stroma/settings/setting.rb"
end
