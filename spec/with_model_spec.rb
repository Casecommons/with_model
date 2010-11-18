# In your spec_helper.rb:

require "active_record"
require "with_model"

if defined?(RSpec)
  # For RSpec 2 users.
  RSpec.configure do |config|
    config.extend WithModel
  end
else
  # For RSpec 1 users.
  Spec::Runner.configure do |config|
    config.extend WithModel
  end
end

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => ":memory:")



# In your spec:

describe "a temporary ActiveRecord model created with with_model" do
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

  it "should act like a normal ActiveRecord model" do
    record = @blog_post.create!(:title => 'New blog post', :content => "Hello, world!")

    record.reload

    record.title.should == 'New blog post'
    record.content.should == 'Hello, world!'
    record.updated_at.should be_present

    record.destroy

    lambda {
      record.reload
    }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it "should have methods defined in its model block" do
    @blog_post.new(:title => 'New blog post').fancy_title.should == "Title: New blog post"
  end
end
