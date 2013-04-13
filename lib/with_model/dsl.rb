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
      const_name = @name.to_s.camelize
      table_name = "with_model_#{@name.to_s.tableize}_#{$$}"

      model = nil

      @example_group.with_table(table_name, @table_options, &@table_block)

      @example_group.before do
        model = Class.new(WithModel::Base)

        @original_const = eval(const_name) rescue nil
        Object.send(:const_set, const_name, model)

        model.class_eval do
          self.table_name = table_name
          self.class_eval(&model_initialization)
        end
        model.reset_column_information
      end

      @example_group.after do
        if model.superclass.respond_to?(:direct_descendants)
          model.superclass.direct_descendants.delete(model)
        end
        if @original_const
          Object.send(:const_set, const_name, @original_const)
        else
          Object.send(:remove_const, const_name) 
        end

        if defined?(ActiveSupport::Dependencies::Reference)
          ActiveSupport::Dependencies::Reference.clear!
        end
      end
    end

  end
end

