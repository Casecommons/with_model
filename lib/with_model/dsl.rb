require 'with_model/base'
require 'active_support/inflector'

module WithModel
  class Dsl
    attr_reader :model_initialization

    def initialize(name, example_group)
      dsl = self

      @example_group = example_group
      @table_name = table_name = "with_model_#{name.to_s.tableize}_#{$$}"
      @model_initialization = lambda {|*|}
      @table_block = lambda {|*|}
      @table_options = {}

      const_name = name.to_s.camelize.to_sym

      original_const_defined = Object.const_defined?(const_name)
      original_const_value = Object.const_get(const_name) if original_const_defined

      model = Class.new(WithModel::Base)

      example_group.before do
        silence_warnings { Object.const_set(const_name, model) }
        Object.const_get(const_name).class_eval do
          set_table_name table_name
          self.class_eval(&dsl.model_initialization)
        end
      end

      example_group.after do
        model._with_model_deconstructor if model.respond_to?(:_with_model_deconstructor)
        Object.send(:remove_const, const_name)
        Object.const_set(const_name, original_const_value) if original_const_defined
      end
    end

    def execute
      @example_group.with_table(@table_name, @table_options, &@table_block)
    end

    def table(options = {}, &block)
      @table_options = options
      @table_block = block
    end

    def model(&block)
      @model_initialization = block
    end
  end
end
