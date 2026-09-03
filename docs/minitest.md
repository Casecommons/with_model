# Minitest integration

Load the Minitest entrypoint before defining tests:

```ruby
require "with_model/minitest"
```

This requires `minitest`, then `with_model`, selects the
`:minitest` runner, and extends `Minitest::Test`. Its class-level DSL is
inherited by `Minitest::Test` subclasses, including `Minitest::Spec` and
`ActiveSupport::TestCase`. The entrypoint does not require or start Minitest's
autorun — your process or test framework owns Minitest startup.

## Lifecycle

The Minitest runner creates declared models and tables in `before_setup` and
destroys them in `after_teardown`. This makes them available to ordinary setup
methods and keeps them available through teardown. `scope:` is silently ignored
by Minitest because it is an RSpec-only option.

## Manual setup

If another process or tool owns Minitest configuration, configure manually:

```ruby
require "minitest"
require "with_model"

WithModel.runner = :minitest
Minitest::Test.extend WithModel
```

Minitest is an optional consumer dependency. Requiring `with_model/minitest`
without Minitest installed raises Minitest's ordinary `LoadError`.

## Mixed runners

Do not load multiple convenience entrypoints in one process: each changes the
global runner, and the last one wins. For mixed runners, load plain
`with_model`, extend each framework boundary directly, and select a runner per
declaration with `runner:`.

See the [general DSL reference](../README.md#usage) for declaring models and
tables.
