require 'spec_helper'

describe "A blog post" do
  before :all do
    module SomeModule; end
  end

  after :all do
    Object.send :remove_const, :SomeModule
  end

  with_model :BlogPost do
    # The table block works just like a migration.
    table do |t|
      t.string :title
      t.timestamps
    end

    # The model block works just like the class definition.
    model do
      include SomeModule
      has_many :comments
      validates_presence_of :title

      def self.some_class_method
        'chunky'
      end

      def some_instance_method
        'bacon'
      end
    end
  end

  # with_model classes can have associations.
  with_model :Comment do
    table do |t|
      t.string :text
      t.belongs_to :blog_post
      t.timestamps
    end

    model do
      belongs_to :blog_post
    end
  end

  it "can be accessed as a constant" do
    BlogPost.should be
  end

  it "has the module" do
    BlogPost.include?(SomeModule).should be_true
  end

  it "has the class method" do
    BlogPost.some_class_method.should == 'chunky'
  end

  it "has the instance method" do
    BlogPost.new.some_instance_method.should == 'bacon'
  end

  it "can do all the things a regular model can" do
    record = BlogPost.new
    record.should_not be_valid
    record.title = "foo"
    record.should be_valid
    record.save.should be_true
    record.reload.should == record
    record.comments.create!(:text => "Lorem ipsum")
    record.comments.count.should == 1
  end
end

describe "another example group" do
  it "should not have the constant anymore" do
    defined?(BlogPost).should be_false
  end
end

describe "with table options" do
  with_model :WithOptions do
    table :id => false do |t|
      t.string 'foo'
      t.timestamps
    end
  end

  it "should respect the additional options" do
    WithOptions.columns.map(&:name).should_not include("id")
  end
end
