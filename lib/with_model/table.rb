require 'active_record'

module WithModel
  class Table
    def initialize name, options = {}, &block
      @name = name.freeze
      @options = options.freeze
      @block = block
    end

    def create
      connection = ActiveRecord::Base.connection
      connection.drop_table(@name) if connection.table_exists?(@name)
      connection.create_table(@name, @options, &@block)
    end

    def destroy
      ActiveRecord::Base.connection.drop_table(@name)
    end
  end
end
