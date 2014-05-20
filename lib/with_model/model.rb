require 'active_record'
require 'active_support/core_ext/string/inflections'
require 'with_model/constant_stubber'
require 'with_model/methods'
require 'with_model/table'

module WithModel
  class Model
    attr_writer :model_block, :table_block, :table_options

    def initialize name, options = {}
      @name = name.to_sym
      @options = options
      @model_block = nil
      @table_block = nil
      @table_options = {}
    end

    def create
      table.create
      @model = Class.new(superclass) do
        extend WithModel::Methods
      end
      stubber.stub_const @model
      setup_model
    end

    def superclass
      @options.fetch(:superclass, ActiveRecord::Base)
    end

    def destroy
      stubber.unstub_const
      remove_from_superclass_descendants
      reset_dependencies_cache
      table.destroy
      @model = nil
    end

    private

    def const_name
      @name.to_s.camelize.to_sym
    end

    def setup_model
      @model.table_name = table_name
      @model.class_eval(&@model_block) if @model_block
      @model.reset_column_information
    end

    def remove_from_superclass_descendants
      return unless @model.superclass.respond_to?(:direct_descendants)
      @model.superclass.direct_descendants.delete(@model)
    end

    def reset_dependencies_cache
      return unless defined?(ActiveSupport::Dependencies::Reference)
      ActiveSupport::Dependencies::Reference.clear!
    end

    def stubber
      @stubber ||= ConstantStubber.new const_name
    end

    def table
      @table ||= Table.new table_name, @table_options, &@table_block
    end

    def table_name
      "with_model_#{@name.to_s.tableize}_#{$$}".freeze
    end
  end
end
