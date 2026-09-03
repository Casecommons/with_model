# RSpec integration

Load the RSpec entrypoint before defining example groups:

```ruby
require "with_model/rspec"
```

The entrypoint requires `rspec/core` and `with_model`, selects the `:rspec`
runner, and extends RSpec example groups through `RSpec.configure`. It does not
start RSpec; the RSpec command-line runner remains in control.

## Lifecycle

`with_model` and `with_table` register RSpec `before` and `after` hooks. Models
and tables are available to examples after setup and are removed after cleanup.
Use `scope:` when RSpec hook scope is needed, including `scope: :all` for a
model needed by `before(:all)`. `scope:` is an RSpec-only option.

## Manual setup

For runner-owned setup, require the framework and `with_model` separately:

```ruby
require "rspec/core"
require "with_model"

WithModel.runner = :rspec
RSpec.configure { |config| config.extend WithModel }
```

RSpec is an optional consumer dependency. Requiring `with_model/rspec` without
RSpec installed raises RSpec's ordinary `LoadError`.

## Mixed runners

Do not load multiple convenience entrypoints in one process: each changes the
global runner, and the last one wins. For mixed runners, load plain
`with_model`, extend each framework boundary directly, and select a runner per
declaration with `runner:`.

See the [general DSL reference](../README.md#usage) for declaring models and
tables.
