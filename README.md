<h1 align="center">Stroma</h1>

<p align="center">
  A hook system framework for building modular DSLs in Ruby.
</p>

<p align="center">
  <a href="https://rubygems.org/gems/stroma"><img src="https://img.shields.io/gem/v/stroma?logo=rubygems&logoColor=fff" alt="Gem version"></a>
  <a href="https://github.com/servactory/stroma/releases"><img src="https://img.shields.io/github/release-date/servactory/stroma" alt="Release Date"></a>
  <a href="https://rubygems.org/gems/stroma"><img src="https://img.shields.io/gem/dt/stroma" alt="Downloads"></a>
  <a href="https://www.ruby-lang.org"><img src="https://img.shields.io/badge/Ruby-3.2+-red" alt="Ruby version"></a>
</p>

<!--
## 📚 Documentation

See [stroma.servactory.com](https://stroma.servactory.com) for documentation, including:

- Architecture overview
- Registry and DSL modules
- Hooks and extensions
- Settings hierarchy
- API reference
-->

## 💡 Why Stroma?

Building modular DSLs shouldn't require reinventing the wheel. Stroma provides a foundation for library authors to create extensible frameworks with:

- 🔌 **Modular Architecture** - Register DSL modules independently, compose them flexibly
- 🪝 **Hook System** - Insert extensions before/after any registered module
- 🏛️ **Inheritance Safe** - Per-class state isolation with automatic deep copying
- ⚙️ **Settings Hierarchy** - Three-level configuration storage for extensions
- 🧩 **Composable Extensions** - Build cross-cutting concerns without modifying core DSL
- 🔒 **Thread Safe** - Immutable registry after finalization, safe concurrent reads

## 🧬 Concept

Stroma is a meta-framework for library authors. It provides the scaffolding to build DSL-driven frameworks like service objects, form objects, or decorators.

**Core lifecycle:**
1. **Register** - Define DSL modules at boot time via `Stroma::Registry`
2. **Include** - Classes include `Stroma::DSL` to gain all registered modules
3. **Extend** - Add cross-cutting logic via `before`/`after` hooks

## 🚀 Quick Start

### Installation

```ruby
gem "stroma"
```

### Define your library's DSL

```ruby
module MyLib
  module DSL
    # Register DSL modules at load time
    Stroma::Registry.register(:inputs, MyLib::Inputs::DSL)
    Stroma::Registry.register(:actions, MyLib::Actions::DSL)
    Stroma::Registry.finalize!

    def self.included(base)
      base.include(Stroma::DSL)
    end
  end
end
```

### Create base class

```ruby
module MyLib
  class Base
    include MyLib::DSL
  end
end
```

### Usage

```ruby
class UserService < MyLib::Base
  input :email, type: String

  make :create_user

  private

  def create_user
    # implementation
  end
end
```

## 🤝 Contributing

We welcome contributions! Check out our [Contributing Guide](https://github.com/servactory/stroma/blob/main/CONTRIBUTING.md) to get started.

**Ways to contribute:**
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🧪 Add test cases
- 🔧 Submit pull requests

## 🙏 Acknowledgments

Special thanks to all our [contributors](https://github.com/servactory/stroma/graphs/contributors)!

## 📄 License

Stroma is available as open source under the terms of the [MIT License](./LICENSE).
