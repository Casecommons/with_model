require 'with_model/base'
require 'active_support/inflector'

module WithModel
  class Dsl
    NOOP = lambda {|*|}

    def initialize(name, example_group)
      @name = name
      @example_group = example_group
      @model_initialization = NOOP
      @table_block = NOOP
      @table_options = {}
    end

    def table(options = {}, &block)
      @table_options = options
      @table_block = block
    end

    def model(&block)
      @model_initialization = block
    end

    def execute
      model_initialization = @model_initialization
      const_name = @name.to_s.camelize.to_sym
      table_name = "with_model_#{@name.to_s.tableize}_#{$$}"

      original_const_defined = Object.const_defined?(const_name)
      original_const_value = Object.const_get(const_name) if original_const_defined

      model = nil

      @example_group.with_table(table_name, @table_options, &@table_block)

      @example_group.before do
        model = Class.new(WithModel::Base)
        silence_warnings { Object.const_set(const_name, model) }
        Object.const_get(const_name).class_eval do
          set_table_name table_name
          self.class_eval(&model_initialization)
        end
        model.reset_column_information
      end

      @example_group.after do
        model._with_model_deconstructor if model.respond_to?(:_with_model_deconstructor)
        Object.send(:remove_const, const_name)
        Object.const_set(const_name, original_const_value) if original_const_defined
      end
    end
  end
end
