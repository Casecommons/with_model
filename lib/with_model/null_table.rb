# frozen_string_literal: true

require "active_record"
require "with_model/invalid_superclass"

module WithModel
  # Stands in for a {WithModel::Table} when a model should not get a table of its
  # own: either it inherits its superclass's table, as Rails Single Table
  # Inheritance requires, or it uses an existing table: one its model block
  # names with `self.table_name`, or the one Active Record names after the
  # model. An abstract model needs neither. Selected by `table(false)`.
  #
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class NullTable
    # @param [Class] superclass The resolved superclass whose table will be
    #   inherited.
    # @param [Symbol, String] name The model's name, so that an error can say
    #   which model it is talking about.
    def initialize(superclass, name)
      @superclass = superclass
      @name = name
    end

    # Creates nothing, but raises {WithModel::InvalidSuperclass} when the
    # superclass has a table that cannot support single table inheritance.
    # Whether a superclass with nothing to inherit is a problem depends on the
    # model block, so that waits for {#verify}.
    #
    # Errors describe the model's situation rather than the call that produced
    # it. Any expression that evaluates to false selects a NullTable, so there
    # is no call spelling to quote - and in with_model 3.0, omitting `table`
    # will arrive here too.
    #
    # A superclass whose table does not exist *yet* is deliberately allowed: the
    # table may be created later in the example, and a test may legitimately
    # want a model whose table is missing. Active Record raises a clear
    # `StatementInvalid` naming the table if it never appears, so raising here
    # would only forbid working setups.
    #
    # What is left is {WithModel::InvalidSuperclass}: a missing inheritance
    # column, like a missing table to inherit, is a permanent fact about the
    # superclass passed in, not about when it was looked at, so no amount of
    # waiting makes it work.
    def create
      # Nothing can be checked until there is a table to look at.
      return unless inheritable_table? && table_exists?
      return if inheritance_column?

      raise_invalid_superclass "#{@superclass}'s table #{@superclass.table_name.inspect} has no " \
             "#{inheritance_column.inspect} column, so Active Record cannot tell its rows " \
             "apart from a subclass's"
    end

    # Deliberately does nothing: leaving `table_name` unassigned is what lets
    # Active Record's own inheritance supply the superclass's table.
    def configure(klass)
    end

    # Raises {WithModel::InvalidSuperclass} when the superclass has no table to
    # inherit (`ActiveRecord::Base`, or an abstract class) and the model's own
    # table - the one its block named, or else the one Active Record names after
    # the model - does not exist once its block has run. A model its block made
    # abstract needs no table, so it always passes.
    #
    # Unlike a superclass's missing table, which {#create} lets through, this
    # table must already exist. A model with nothing to inherit is far more
    # likely a mistaken attempt at single table inheritance than a deliberate
    # reference to a table that is yet to be created, and with nothing to point
    # at, Active Record's own error would leave that mistake unexplained.
    def verify(klass)
      return if klass.abstract_class? || inheritable_table? || own_table_exists?(klass)

      raise_invalid_superclass "#{@superclass} has none to inherit and there is no " \
        "#{klass.table_name.inspect} table. To use an existing table, create it before " \
        "the model or set `self.table_name` in its model block."
    end

    # Removes the rows a single table inheritance subclass wrote, which would
    # otherwise outlive the constant that names them and make the superclass
    # unloadable (`ActiveRecord::SubclassNotFound`).
    #
    # A model that is its own base class names a table that belongs to the
    # suite, and its rows name no class, so they are left for the suite to clean
    # up like the rest of that table - its table need not have an inheritance
    # column to delete by, either.
    #
    # `unscoped` is required because a `default_scope` on the superclass would
    # otherwise hide rows from cleanup; the inheritance-column condition is
    # then reapplied explicitly, since `unscoped` also discards the type
    # condition that keeps this from touching the superclass's own rows.
    #
    # A table that does not exist holds no rows to remove, and failing here
    # would fail an example whose body had already passed.
    def teardown(klass)
      return if klass.base_class? || !klass.table_exists?

      klass.unscoped.where(klass.inheritance_column => klass.sti_name).each(&:destroy!)
    end

    # Drops nothing; there is no table of our own to drop.
    def destroy
    end

    private

    def inheritance_column = @superclass.inheritance_column

    # `ActiveRecord::Base` has no `table_name`, and an abstract class has none to
    # pass on through single table inheritance even when it has one: Active
    # Record makes each of its subclasses a base class of its own. Neither test
    # covers both, since `abstract_class?` is false for `ActiveRecord::Base`.
    def inheritable_table? = !@superclass.abstract_class? && @superclass.table_name.present?

    def own_table_exists?(klass) = klass.connection.data_source_exists?(klass.table_name)

    def table_exists? = @superclass.table_exists?

    def inheritance_column?
      inheritance_column.present? && @superclass.columns_hash.key?(inheritance_column)
    end

    def raise_invalid_superclass(problem)
      raise InvalidSuperclass,
        "with_model #{@name.inspect} has no table of its own, but #{problem}"
    end
  end
end
