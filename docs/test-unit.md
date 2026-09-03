# Test::Unit integration

Load the Test::Unit entrypoint before defining tests:

```ruby
require "with_model/test_unit"
```

The entrypoint requires `test/unit`, then `with_model`, selects the
`:test_unit` runner, and extends `Test::Unit::TestCase`. Test::Unit retains
ownership of autorun and fixture execution.

## Lifecycle

`with_model` and `with_table` register Test::Unit fixture callbacks with exact
placement: setup uses `before: :append`, while teardown uses `after: :prepend`.
Declared models and tables therefore create in declaration order before user or
inherited setup methods and callbacks. They destroy in reverse order after user
or inherited teardown methods and callbacks.

Test::Unit runs teardown when setup raises. `WithModel::Model#destroy`
defensively handles creation that never assigned a model. `Table#destroy` checks
whether its table exists before dropping it, so teardown does not raise solely
because a reconnect replaced an in-memory database or the table otherwise
already disappeared. It does not rescue other database, connection, or drop
errors; those still propagate. This conditional drop check does not promise
generic partial-creation recovery for bare `with_table`. `scope:` is silently
ignored by Test::Unit because it is an RSpec-only option.

## Errata and concerns

Establish the Active Record connection before `with_model`'s setup callback
creates tables and models. An ordinary `def setup` runs too late. Connect in
your test helper before test classes load, or register a connection callback
with `setup(before: :prepend)`.

```ruby
class PostTest < Test::Unit::TestCase
  setup(before: :prepend) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

  with_model :Post do
    table
  end
end
```

## Manual setup

For runner-owned setup, require Test::Unit and `with_model` separately:

```ruby
require "test/unit"
require "with_model"

WithModel.runner = :test_unit
Test::Unit::TestCase.extend WithModel
```

Test::Unit is an optional consumer dependency. Requiring
`with_model/test_unit` without Test::Unit installed raises Test::Unit's ordinary
`LoadError`.

## Mixed runners

Do not load multiple convenience entrypoints in one process: each changes the
global runner, and the last one wins. For mixed runners, load plain
`with_model`, extend each framework boundary directly, and select a runner per
declaration with `runner:`.

See the [general DSL reference](../README.md#usage) for declaring models and
tables.
