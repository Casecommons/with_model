# frozen_string_literal: true

require "logger"
require "active_record"
require "active_support/core_ext/string/inflections"
require "English"
require "with_model/constant_stubber"
require "with_model/descendants_tracker"
require "with_model/methods"
require "with_model/invalid_superclass"
require "with_model/missing_superclass"
require "with_model/null_table"
require "with_model/table"

module WithModel
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class Model
    attr_writer :model_block, :table_block, :table_options

    # @param [Symbol] name The constant name to assign the model class to.
    # @param superclass The superclass for the created class. Either a Class
    #   having `ActiveRecord::Base` as an ancestor, a String naming one, or a
    #   callable returning one. A String or callable is resolved afresh for
    #   every example, which is what allows another `with_model` model - whose
    #   constant does not exist when this line is read - to be the superclass.
    def initialize(name, superclass: ActiveRecord::Base)
      @name = name.to_sym
      @model_block = nil
      @table_block = nil
      @table_options = {}
      @table_specified = false
      @skip_table = false
      @superclass_spec = superclass
    end

    # Records what {WithModel::Model::DSL#table} was asked for, including the
    # fact that it was asked for at all.
    def specify_table(options, block)
      @table_specified = true

      if options == false
        raise ArgumentError, "table does not take a block when its first argument is falsy" if block

        @skip_table = true
      else
        @table_options = options
        @table_block = block
      end
    end

    # Whether a table was specified at all. A `table` call with no arguments
    # counts, so this cannot be inferred from the options and block alone.
    def table_specified? = @table_specified

    def create
      @superclass = resolve_superclass
      @table = nil
      table.create
      @model = Class.new(@superclass) do
        extend WithModel::Methods
      end
      stubber.stub_const @model
      setup_model
    end

    def destroy
      # Test runners tear down even when setup raised, so `create` may not have
      # reached the point of building the model. Nothing was stubbed and nothing
      # wrote rows, so there is nothing to undo.
      return unless @model

      # Before `unstub_const`: a teardown that identifies this model's own rows
      # can only do so while the class still has its name.
      table.teardown(@model)
      stubber.unstub_const
      cleanup_descendants_tracking
      reset_dependencies_cache
      WithModel::DescendantsTracker.clear([@model])
      @model = nil
    end

    private

    def resolve_superclass
      spec = @superclass_spec
      spec = spec.call if spec.respond_to?(:call)
      spec = constantize_superclass(spec) if class_name?(spec)

      unless spec.is_a?(Class) && spec <= ActiveRecord::Base
        raise InvalidSuperclass,
          "superclass must be a Class descending from ActiveRecord::Base, but was #{spec.inspect}. " \
          "To refer to another with_model class, or anything else that is only defined once the " \
          "test is running, name it with a String or a Symbol, or pass a callable returning it."
      end

      spec
    end

    # A Symbol reads naturally here, since with_model names its own models with
    # them. Anything else has to answer to `to_str`, which only real strings do:
    # every object has a `to_s`, so accepting that would quietly look up a
    # constant named "42".
    def class_name?(spec)
      spec.is_a?(Symbol) || spec.respond_to?(:to_str)
    end

    # `to_s` is safe here where `class_name?` has already vouched for the value,
    # and it keeps the Symbol intact for the message below, which reports what was
    # passed in rather than what it was converted to.
    #
    # The NameError is worth quoting rather than replacing: for a namespaced name
    # it reports which segment was missing, which this message cannot work out.
    # Raising inside the rescue leaves it as the `cause` for anything that wants
    # the backtrace.
    def constantize_superclass(name)
      name.to_s.constantize
    rescue NameError => e
      raise MissingSuperclass,
        "superclass #{name.inspect} could not be resolved: #{e.message}. Names are resolved while " \
        "the test is running, so a with_model superclass has to be declared before the models " \
        "that inherit it."
    end

    def const_name
      @name.to_s.camelize.to_sym
    end

    def setup_model
      table.configure(@model)
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
      @table ||= if @skip_table
        NullTable.new(@superclass, @name)
      else
        Table.new table_name, @table_options, connection: @superclass.connection, &@table_block
      end
    end

    def table_name
      uid = "#{$PID}_#{Thread.current.object_id}"
      "with_model_#{@name.to_s.tableize}_#{uid}"
    end
  end
end
