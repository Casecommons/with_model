module WithModel
  autoload :Base, "with_model/base"
  autoload :Dsl, "with_model/dsl"
  autoload :VERSION, "with_model/version"

  def with_model(name, &block)
    Dsl.new(name, self).tap { |dsl| dsl.instance_eval(&block) }.execute
  end

  def with_table(name, options = {}, &block)
    connection = ActiveRecord::Base.connection

    before do
      connection.drop_table(name) if connection.table_exists?(name)
      connection.create_table(name, options, &block)
    end

    after do
      connection.drop_table(name)
    end
  end
end
