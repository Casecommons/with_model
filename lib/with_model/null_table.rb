# frozen_string_literal: true

require "active_record"
require "with_model/invalid_superclass"

module WithModel
  # Stands in for a {WithModel::Table} when a model should inherit its
  # superclass's table instead of getting one of its own, as Rails Single Table
  # Inheritance requires. Selected by `table(false)`.
  #
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class NullTable
    # @param [Class] superclass The resolved superclass whose table will be
    #   inherited.
    # @param [Symbol, String] name The model's name, so that a refusal can say
    #   which model it is talking about.
    def initialize(superclass, name)
      @superclass = superclass
      @name = name
    end

    # Creates nothing, but refuses a superclass that cannot support single
    # table inheritance.
    #
    # Refusals describe the model's situation rather than the call that produced
    # it. Any expression that evaluates to false selects a NullTable, so there
    # is no call spelling to quote - and in with_model 3.0, omitting `table`
    # will arrive here too.
    #
    # A superclass whose table does not exist *yet* is deliberately allowed: the
    # table may be created later in the example, and a test may legitimately
    # want a model whose table is missing. Active Record raises a clear
    # `StatementInvalid` naming the table if it never appears, so refusing here
    # would only forbid working setups.
    #
    # What is left is {WithModel::InvalidSuperclass}: both refusals are permanent
    # facts about the superclass passed in, not about when it was looked at, so no
    # amount of waiting makes them work.
    def create
      refuse "#{@superclass} has none to inherit" unless table_name?

      # Nothing more can be checked until there is a table to look at.
      return unless table_exists?
      return if inheritance_column?

      refuse "#{@superclass}'s table #{@superclass.table_name.inspect} has no " \
             "#{inheritance_column.inspect} column, so Active Record cannot tell its rows " \
             "apart from a subclass's"
    end

    # Deliberately does nothing: leaving `table_name` unassigned is what lets
    # Active Record's own inheritance supply the superclass's table.
    def configure(klass)
    end

    # Removes the rows this model wrote, which would otherwise outlive the
    # constant that names them and make the superclass unloadable
    # (`ActiveRecord::SubclassNotFound`).
    #
    # `unscoped` is required because a `default_scope` on the superclass would
    # otherwise hide rows from the delete; the inheritance-column condition is
    # then reapplied explicitly, since `unscoped` also discards the type
    # condition that keeps this from touching the superclass's own rows.
    #
    # A table that does not exist holds no rows to remove, and failing here
    # would fail an example whose body had already passed.
    def teardown(klass)
      return unless klass.table_exists?

      klass.unscoped.where(klass.inheritance_column => klass.sti_name).delete_all
    end

    # Drops nothing; there is no table of our own to drop.
    def destroy
    end

    private

    def inheritance_column = @superclass.inheritance_column

    # `ActiveRecord::Base` and abstract classes alike have no `table_name`, so
    # this is what "nothing to inherit" actually looks like - `abstract_class?`
    # is false for `ActiveRecord::Base` and so does not describe both.
    def table_name? = @superclass.table_name.present?

    def table_exists? = @superclass.table_exists?

    def inheritance_column?
      inheritance_column.present? && @superclass.columns_hash.key?(inheritance_column)
    end

    def refuse(problem)
      raise InvalidSuperclass,
        "with_model #{@name.inspect} has no table of its own, but #{problem}"
    end
  end
end
