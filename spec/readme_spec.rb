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
      t.timestamps null: false
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
      t.timestamps null: false
    end

    model do
      belongs_to :blog_post
    end
  end

  it "can be accessed as a constant" do
    expect(BlogPost).to be
  end

  it "has the module" do
    expect(BlogPost.include?(SomeModule)).to eq true
  end

  it "has the class method" do
    expect(BlogPost.some_class_method).to eq 'chunky'
  end

  it "has the instance method" do
    expect(BlogPost.new.some_instance_method).to eq 'bacon'
  end

  it "can do all the things a regular model can" do
    record = BlogPost.new
    expect(record).to_not be_valid
    record.title = "foo"
    expect(record).to be_valid
    expect(record.save).to eq true
    expect(record.reload).to eq record
    record.comments.create!(:text => "Lorem ipsum")
    expect(record.comments.count).to eq 1
  end

  # with_model classes can have inheritance.
  class Car < ActiveRecord::Base
    self.abstract_class = true
  end

  with_model :Ford, superclass: Car do
  end

  it "has a specified superclass" do
    expect(Ford < Car).to eq true
  end
end

describe "with_model can be run within RSpec :all hook" do
  with_model :BlogPost, scope: :all do
    table do |t|
      t.string :title
    end
  end

  before :all do
    BlogPost.create # without scope: :all these will fail
  end

  it "has been initialized within before(:all)" do
    expect(BlogPost.count).to eq 1
  end
end

describe "another example group" do
  it "does not have the constant anymore" do
    expect(defined?(BlogPost)).to be_falsy
  end
end

describe "with table options" do
  with_model :WithOptions do
    table :id => false do |t|
      t.string 'foo'
      t.timestamps null: false
    end
  end

  it "respects the additional options" do
    expect(WithOptions.columns.map(&:name)).to_not include("id")
  end
end
