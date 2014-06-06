require 'with_model/model'
require 'with_model/model/dsl'
require 'with_model/table'
require 'with_model/version'

module WithModel
  def with_model(name, options = {}, &block)
    options = options.dup
    scope = options.delete(:scope)

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

  def with_table(name, options = {}, &block)
    options = options.dup
    scope = options.delete(:scope)

    table = Table.new name, options, &block

    before(*scope) do
      table.create
    end

    after(*scope) do
      table.destroy
    end
  end
end
