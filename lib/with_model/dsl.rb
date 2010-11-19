module WithModel
  class Dsl
    attr_reader :model_initialization

    def initialize(name, example_group)
      dsl = self

      @example_group = example_group
      @table_name = table_name = "with_model_#{name}_#{$$}"
      @model_initialization = lambda {|*|}

      const_name = name.to_s.camelize.to_sym

      original_const_defined = Object.const_defined?(const_name)
      original_const_value = Object.const_get(const_name) if original_const_defined

      example_group.class_eval do
        attr_accessor name
      end

      example_group.before do
        model = Class.new(ActiveRecord::Base)
        silence_warnings { Object.const_set(const_name, model) }
        Object.const_get(const_name).class_eval do
          set_table_name table_name
          class << self
            def with_model?
              true
            end
          end
          self.class_eval(&dsl.model_initialization)
        end
        send("#{name}=", model)
      end

      example_group.after do
        Object.send(:remove_const, const_name)
        Object.const_set(const_name, original_const_value) if original_const_defined
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
