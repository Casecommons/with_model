require 'with_model/dsl'
require 'with_model/table'
require 'with_model/version'

module WithModel
  def with_model(name, &block)
    dsl = Dsl.new(name)
    dsl.instance_exec(&block) if block
    dsl.run_with_table self
    before { dsl.run_before }
    after { dsl.run_after }
  end

  def with_table(name, options = {}, &block)
    table = Table.new name, options, &block
    before { table.create }
    after { table.destroy }
  end
end
