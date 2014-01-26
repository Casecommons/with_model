require 'with_model/model'
require 'with_model/model/dsl'
require 'with_model/table'
require 'with_model/version'

module WithModel
  def with_model(name, options = {}, &block)
    model = Model.new name, options
    dsl = Model::DSL.new model
    dsl.instance_exec(&block) if block

    before scope(options) do
      model.create
    end

    after scope(options) do
      model.destroy
    end
  end

  def with_table(name, options = {}, &block)
    table = Table.new name, options, &block

    before scope(options) do
      table.create
    end

    after scope(options) do
      table.destroy
    end
  end

  def scope options = {}
    if options[:scope]
      options[:scope].to_sym
    else
      :each
    end
  end
end
