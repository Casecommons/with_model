# frozen_string_literal: true

require "logger"
require "active_record"
require "active_support/core_ext/string/inflections"
require "English"
require "with_model/constant_stubber"
require "with_model/descendants_tracker"
require "with_model/methods"
require "with_model/table"

module WithModel
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class Model
    attr_writer :model_block, :table_block, :table_options

    # @param [Symbol] name The constant name to assign the model class to.
    # @param [Class] superclass The superclass for the created class. Should
    #   have `ActiveRecord::Base` as an ancestor.
    def initialize(name, superclass: ActiveRecord::Base)
      @name = name.to_sym
      @model_block = nil
      @table_block = nil
      @table_options = {}
      @superclass = superclass
    end

    def create
      table.create
      @model = Class.new(@superclass) do
        extend WithModel::Methods
      end
      stubber.stub_const @model
      setup_model
    end

    def destroy
      stubber.unstub_const
      cleanup_descendants_tracking
      reset_dependencies_cache
      table.destroy
      WithModel::DescendantsTracker.clear([@model])
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

    def cleanup_descendants_tracking
      ActiveSupport::DescendantsTracker.clear([@model]) \
        unless ActiveSupport::DescendantsTracker.clear_disabled
    end

    def reset_dependencies_cache
      return unless defined?(ActiveSupport::Dependencies::Reference)

      ActiveSupport::Dependencies::Reference.clear!
    end

    def stubber
      @stubber ||= ConstantStubber.new const_name
    end

    def table
      @table ||= Table.new table_name, @table_options, connection: @superclass.connection, &@table_block
    end

    def table_name
      uid = "#{$PID}_#{Thread.current.object_id}"
      "with_model_#{@name.to_s.tableize}_#{uid}"
    end
  end
end
