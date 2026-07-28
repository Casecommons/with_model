# Contributing to with_model

If you experience a bug, we welcome you to report it. Please include a minimal
example showing the code you ran, what happened, and what you expected to happen
instead — a failing `with_model` block is ideal, since it can be dropped straight
into the suite. If you can fix the bug and open a pull request, it will get
resolved sooner, but don't hesitate to report an issue you don't know how to fix.

If you have a substantial feature in mind, consider opening an issue to discuss
it first. We may have thought about it already, and can sometimes save you a
detour.

When in doubt, go ahead and open a pull request. If something needs rethinking,
we will do our best to say so clearly. Don't be discouraged if we ask you to
change your code — we appreciate the work, and we also have opinions about style
and object design.

## Supported versions

The [gemspec](./with_model.gemspec) declares the minimum supported Ruby and
Active Record, and the [CI workflow](./.github/workflows/ci.yml) lists every
combination actually tested. It can be hard to try them all locally, so please
avoid anything that only works on the newest of either.

## Running the tests

The suite runs against both supported test harnesses, so `with_model` has to work
under each:

- `spec/` covers behavior under RSpec.
- `test/` covers the minitest life cycle — the setup and teardown hooks, and
  their ordering — rather than repeating the specs.

Run everything, including the linter, with:

```sh
bundle exec rake
```

`bin/` holds generated binstubs and is not checked in. Whether bundling writes
them for you depends on your Bundler version, so create them once if you would
rather type `bin/rake`:

```sh
bundle binstubs --all
```

Our automated tests begin by updating every gem to its newest version. That is
deliberate: we would rather find out about an incompatibility from our own build
than from a bug report. `Gemfile.lock` is not checked in, so you can do the same
at any time with `bundle update --all`.

To try a particular Active Record, set `ACTIVE_RECORD_VERSION` to a version
requirement and update the bundle:

```sh
ACTIVE_RECORD_VERSION="~> 8.1.0" bundle update --all
ACTIVE_RECORD_VERSION="~> 8.1.0" bundle exec rake
```

To test against Active Record from git instead — an unreleased branch, or `main`
— set `ACTIVE_RECORD_BRANCH`:

```sh
ACTIVE_RECORD_BRANCH=main bundle update --all
ACTIVE_RECORD_BRANCH=main bundle exec rake
```

Style is enforced by [Standard](https://github.com/standardrb/standard), which
`rake` runs. To correct what it can:

```sh
bundle exec standardrb --fix
```

## Changes and releases

Please add a line to `CHANGELOG.md` under `### Unreleased` describing your change
from the point of view of someone using the gem. Leave `lib/with_model/version.rb`
alone: version bumps and releases are cut separately by a maintainer, so a bump
in a pull request only creates a conflict.

Last, but not least, have fun.
