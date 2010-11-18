require "active_record"
require "with_model"

if defined?(RSpec)
  RSpec.configure do |config|
    config.extend WithModel
  end
else
  Spec::Runner.configure do |config|
    config.extend WithModel
  end
end

ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => ":memory:")
connection = ActiveRecord::Base.connection
connection.execute("SELECT 1")

describe "an ActiveRecord model" do
  with_model :blog_post do
    table do |t|
      t.string 'title'
      t.text 'content'
      t.timestamps
    end

    model do
      def fancy_title
        "Title: #{title}"
      end
    end
  end

  it "should save properly" do
    lambda {
      @blog_post.create!(:title => 'New blog post', :content => "Hello, world!")
    }.should_not raise_error
  end
end
