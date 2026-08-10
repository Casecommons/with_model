# frozen_string_literal: true

require "active_record"

module WithModel
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class Table
    # @param [Symbol] name The name of the table to create.
    # @param options Passed to ActiveRecord `create_table`.
    # @param connection The connection to use for creating the table.
    # @param block Passed to ActiveRecord `create_table`.
    # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table
    def initialize(name, options = {}, connection: ActiveRecord::Base.connection, &block)
      @name = name.freeze
      @options = options.freeze
      @block = block
      @connection = connection
    end

    # Creates the table with the initialized options. Drops the table if
    # it already exists.
    def create
      connection.drop_table(@name) if exists?
      connection.create_table(@name, **@options, &@block)
    end

    # Points the model at this table.
    def configure(klass)
      klass.table_name = @name
    end

    # Removes everything this table holds by dropping it. The model is not
    # needed, but is accepted so that {WithModel::NullTable} - which does need
    # it - can stand in here.
    def teardown(_klass)
      destroy
    end

    def destroy
      connection.drop_table(@name)
    end

    private

    attr_reader :connection

    def exists? = connection.data_source_exists?(@name)
  end
end
