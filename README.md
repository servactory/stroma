<h1 align="center">Stroma</h1>

<p align="center">
  A foundation for building modular, extensible DSLs in Ruby.
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

Building modular DSLs shouldn't require reinventing the wheel. Stroma provides a structured approach for library authors to compose DSL modules with:

- 🔌 **Module Registration** - Register DSL modules at boot time, compose them into a unified interface
- 🧱 **Structured Composition** - Include all registered modules automatically via single DSL entry point
- 🏛️ **Inheritance Safe** - Per-class state isolation with automatic deep copying
- 🪝 **Extension Hooks** - Optional before/after hooks for user customization
- ⚙️ **Extension Settings** - Three-level hierarchical storage for extension configuration
- 🔒 **Thread Safe** - Immutable registry after finalization, safe concurrent reads

## 🧬 Concept

Stroma is a foundation for library authors building DSL-driven frameworks (service objects, form objects, decorators, etc.).

**Core lifecycle:**
1. **Define** - Create a Matrix with DSL modules at boot time
2. **Include** - Classes include the matrix's DSL to gain all modules
3. **Extend** (optional) - Add cross-cutting logic via `before`/`after` hooks

## 🚀 Quick Start

### Installation

```ruby
spec.add_dependency "stroma", ">= 0.4"
```

### Define your library's DSL

```ruby
module MyLib
  STROMA = Stroma::Matrix.define(:my_lib) do
    register :inputs, MyLib::Inputs::DSL
    register :actions, MyLib::Actions::DSL
  end
  private_constant :STROMA
end
```

### Create base class

```ruby
module MyLib
  class Base
    include STROMA.dsl
  end
end
```

### Usage

Create an intermediate class with lifecycle hooks:

```ruby
class ApplicationService < MyLib::Base
  # Add lifecycle hooks (optional)
  extensions do
    before :actions, ApplicationService::Extensions::Rollbackable::DSL
  end
end
```

Build services that inherit extension functionality:

```ruby
class UserService < ApplicationService
  # DSL method from Rollbackable extension
  on_rollback(...)

  input :email, type: String

  make :create_user

  private

  def create_user
    # implementation
  end
end
```

Extensions allow you to add cross-cutting concerns like transactions, authorization, and rollback support. See [extension examples](https://github.com/servactory/servactory/tree/main/examples/application_service/extensions) for implementation details.

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
