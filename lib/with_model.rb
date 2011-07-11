require "with_model/dsl"

module WithModel
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
      connection.drop_table(name) rescue nil
    end
  end
end
