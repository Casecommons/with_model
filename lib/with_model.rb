# frozen_string_literal: true

require "active_support/deprecation"
require "with_model/invalid_superclass"
require "with_model/missing_superclass"
require "with_model/model"
require "with_model/model/dsl"
require "with_model/null_table"
require "with_model/table"
require "with_model/version"

module WithModel
  class MiniTestLifeCycle < Module
    def initialize(object)
      # Each with_model includes a fresh module, so the last one declared sits
      # earliest in the ancestor chain. Calling super() first means setup runs
      # in declaration order while teardown unwinds in reverse, which is what
      # lets one with_model refer to another declared above it.
      define_method :before_setup do
        super() if defined?(super)
        object.create
      end

      define_method :after_teardown do
        object.destroy
        super() if defined?(super)
      end
    end

    def self.call(object)
      new(object)
    end
  end

  class << self
    attr_writer :runner
  end

  def self.runner
    @runner ||= :rspec
  end

  # The deprecator used for with_model's own deprecation warnings. Callers can
  # silence it (`WithModel.deprecator.silenced = true`) or escalate it
  # (`behavior = :raise`) while migrating, and Rails applications can register
  # it in `Rails.application.deprecators`.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("3.0", "with_model")
  end

  # @param [Symbol] name The constant name to assign the model class to.
  # @param scope Passed to `before`/`after` in the test context. RSpec only.
  # @param options Passed to {WithModel::Model#initialize}.
  # @param block Yielded an instance of {WithModel::Model::DSL}.
  def with_model(name, scope: nil, **options, &block)
    runner = options.delete(:runner)
    model = Model.new name, **options
    dsl = Model::DSL.new model
    dsl.instance_exec(&block) if block
    # caller_locations(1) is this method's caller: the `with_model` line itself.
    WithModel.warn_omitted_table(name, caller_locations(1)) unless model.table_specified?

    setup_object(model, scope: scope, runner: runner)
  end

  # @param [Symbol] name The table name to create.
  # @param scope Passed to `before`/`after` in the test context. Rspec only.
  # @param options Passed to {WithModel::Table#initialize}.
  # @param block Passed to {WithModel::Table#initialize} (like {WithModel::Model::DSL#table}).
  def with_table(name, scope: nil, **options, &block)
    runner = options.delete(:runner)
    table = Table.new name, options, &block

    setup_object(table, scope: scope, runner: runner)
  end

  # Warns once per call site, at definition time, rather than once per example.
  # The horizon is stated in the message because `Deprecation#warn` does not
  # interpolate the deprecator's `deprecation_horizon`.
  #
  # The callstack has to be handed in. `ActiveSupport::Deprecation` skips Rails'
  # own frames and the standard library when working out where a warning came
  # from, but with_model's frames look like anyone else's to it, so left to itself
  # it reports this file for every omission in a suite.
  #
  # @param callstack Frames to blame, beginning with the caller to report.
  def self.warn_omitted_table(name, callstack)
    deprecator.warn(
      "with_model #{name.inspect} was called without a `table`, which creates a table with only " \
      "an id column. In with_model 3.0 no table will be created. Call `table` (with no " \
      "arguments or an empty block) to keep a table, or `table(false)` to inherit the " \
      "superclass's table (single table inheritance).",
      callstack
    )
  end

  private

  # @param [Object] object The new model object instance to create
  # @param scope Passed to `before`/`after` in the test context. Rspec only.
  # @param [Symbol] runner The test running, either :rspec or :minitest, defaults to :rspec
  def setup_object(object, scope: nil, runner: nil)
    case runner || WithModel.runner
    when :rspec
      before(*scope) do
        object.create
      end

      after(*scope) do
        object.destroy
      end
    when :minitest
      class_eval do
        include MiniTestLifeCycle.call(object)
      end
    when :test_unit
      # These options place creation before and destruction after user callbacks,
      # preserving declaration and reverse order across inheritance.
      setup(before: :append) { object.create }
      teardown(after: :prepend) { object.destroy }
    else
      raise ArgumentError, "Unsupported test runner set, expected :rspec, :minitest, or :test_unit"
    end
  end
end
