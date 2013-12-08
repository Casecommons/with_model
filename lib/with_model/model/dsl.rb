module WithModel
  class Model
    class DSL
      def initialize model
        @model = model
      end

      def table options = {}, &block
        @model.table_options = options
        @model.table_block = block
      end

      def model &block
        @model.model_block = block
      end
    end
  end
end
