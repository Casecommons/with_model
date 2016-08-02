require 'active_record'

module WithModel
  class Table
    def initialize name, options = {}, &block
      @name = name.freeze
      @options = options.freeze
      @block = block
    end

    def create
      connection.drop_table(@name) if exists?
      connection.create_table(@name, @options, &@block)
    end

    def destroy
      ActiveRecord::Base.connection.drop_table(@name)
    end

    private

    def exists?
      if connection.respond_to?(:data_source_exists?)
        connection.data_source_exists?(@name)
      else
        connection.table_exists?(@name)
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
