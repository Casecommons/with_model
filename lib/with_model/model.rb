require 'active_support/core_ext/string/inflections'
require 'with_model/base'
require 'with_model/table'

module WithModel
  class Model
    attr_writer :model_block, :table_block, :table_options

    def initialize name
      @name = name.to_sym
      @model_block = proc {}
      @table_block = proc {}
      @table_options = {}
    end

    def create
      table.create
      @model = create_model
      stub_const
    end

    def destroy
      unstub_const
      remove_from_superclass_descendants
      reset_dependencies_cache
      table.destroy
      @model = nil
    end

    private

    def const_name
      @name.to_s.camelize.freeze
    end

    def create_model
      model = Class.new(WithModel::Base)

      model_block = @model_block
      table_name = send :table_name
      model.class_eval do
        self.table_name = table_name
        class_eval(&model_block)
      end
      model.reset_column_information

      model
    end

    def remove_from_superclass_descendants
      return unless @model.superclass.respond_to?(:direct_descendants)
      @model.superclass.direct_descendants.delete(@model)
    end

    def reset_dependencies_cache
      return unless defined?(ActiveSupport::Dependencies::Reference)
      ActiveSupport::Dependencies::Reference.clear!
    end

    def table
      @table ||= Table.new table_name, @table_options, &@table_block
    end

    def table_name
      "with_model_#{@name.to_s.tableize}_#{$$}".freeze
    end

    def stub_const
      if Object.const_defined?(const_name)
        @original_const = Object.const_get(const_name)
        Object.send :remove_const, const_name
      end

      Object.const_set const_name, @model
    end

    def unstub_const
      Object.send :remove_const, const_name
      Object.const_set const_name, @original_const if @original_const
    end
  end
end
