module WithModel
  class Dsl
    attr_reader :model_initialization

    def initialize(name, example_group)
      dsl = self

      @example_group = example_group
      @table_name = table_name = "with_model_#{name}_#{$$}"
      @model_initialization = lambda {}

      example_group.class_eval do
        attr_accessor name
      end

      example_group.before do
        send("#{name}=", Class.new(ActiveRecord::Base) do
          set_table_name table_name
          self.class_eval(&dsl.model_initialization)
        end)
      end
    end

    def table(&block)
      @example_group.with_table(@table_name, &block)
    end

    def model(&block)
      @model_initialization = block
    end
  end
end
