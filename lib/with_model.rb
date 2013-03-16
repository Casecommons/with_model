module WithModel
  autoload :Base, "with_model/base"
  autoload :Dsl, "with_model/dsl"
  autoload :VERSION, "with_model/version"

  def with_model(name, &block)
    dsl = Dsl.new(name, self)
    dsl.instance_eval(&block) if block
    dsl.execute
  end

  def with_table(name, options = {}, &block)
    before do
      connection = ActiveRecord::Base.connection
      connection.drop_table(name) if connection.table_exists?(name)
      connection.create_table(name, options, &block)
    end

    after do
      ActiveRecord::Base.connection.drop_table(name)
    end
  end
end
