require 'active_support/core_ext/string/inflections'
require 'with_model/base'

module WithModel
  class Dsl
    NOOP = lambda {|*|}

    def initialize(name)
      @name = name
      @model_initialization = NOOP
      @table_block = NOOP
      @table_options = {}
    end

    def table(options = {}, &block)
      @table_options = options
      @table_block = block
    end

    def model(&block)
      @model_initialization = block if block_given?
    end

    def run_with_table context
      context.with_table(table_name, @table_options, &@table_block)
    end

    def run_before
      @model = Class.new(WithModel::Base)

      raise unless @model_initialization
      model_initialization = @model_initialization
      table_name = send :table_name
      @model.class_eval do
        self.table_name = table_name
        class_eval(&model_initialization)
      end
      @model.reset_column_information

      stub_const
    end

    def run_after
      unstub_const

      if @model.superclass.respond_to?(:direct_descendants)
        @model.superclass.direct_descendants.delete(@model)
      end
      if defined?(ActiveSupport::Dependencies::Reference)
        ActiveSupport::Dependencies::Reference.clear!
      end
    end

    private

    def const_name
      @name.to_s.camelize.freeze
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
