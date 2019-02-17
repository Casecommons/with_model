# frozen_string_literal: true

require 'with_model/model'
require 'with_model/model/dsl'
require 'with_model/table'
require 'with_model/version'

module WithModel
  # @param [Symbol] name The constant name to assign the model class to.
  # @param scope Passed to `before`/`after` in the test context.
  # @param options Passed to {WithModel::Model#initialize}.
  # @param block Yielded an instance of {WithModel::Model::DSL}.
  def with_model(name, scope: nil, **options, &block)
    model = Model.new name, options
    dsl = Model::DSL.new model
    dsl.instance_exec(&block) if block

    before(*scope) do
      model.create
    end

    after(*scope) do
      model.destroy
    end
  end

  # @param [Symbol] name The table name to create.
  # @param scope Passed to `before`/`after` in the test context.
  # @param options Passed to {WithModel::Table#initialize}.
  # @param block Passed to {WithModel::Table#initialize} (like {WithModel::Model::DSL#table}).
  def with_table(name, scope: nil, **options, &block)
    table = Table.new name, options, &block

    before(*scope) do
      table.create
    end

    after(*scope) do
      table.destroy
    end
  end
end
