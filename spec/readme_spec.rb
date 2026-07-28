# frozen_string_literal: true

require "spec_helper"

describe "A blog post" do
  before do
    stub_const("MyModule", Module.new)
  end

  with_model :BlogPost do
    # The table block works just like a migration.
    table do |t|
      t.string :title
      t.timestamps null: false
    end

    # The model block works just like the class definition.
    model do
      include MyModule

      has_many :comments
      validates_presence_of :title

      def self.some_class_method
        "chunky"
      end

      def some_instance_method
        "bacon"
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
    expect(BlogPost.include?(MyModule)).to be true
  end

  it "has the class method" do
    expect(BlogPost.some_class_method).to eq "chunky"
  end

  it "has the instance method" do
    expect(BlogPost.new.some_instance_method).to eq "bacon"
  end

  it "can do all the things a regular model can" do
    record = BlogPost.new
    expect(record).not_to be_valid
    record.title = "foo"
    expect(record).to be_valid
    expect(record.save).to be true
    expect(record.reload).to eq record
    record.comments.create!(text: "Lorem ipsum")
    expect(record.comments.count).to eq 1
  end

  # with_model classes can have inheritance.
  class Car < ActiveRecord::Base # standard:disable Lint/ConstantDefinitionInBlock
    self.abstract_class = true
  end

  with_model :Ford, superclass: Car do
    table
  end

  it "has a specified superclass" do
    expect(Ford.new).to be_a(Car)
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
    table id: false do |t|
      t.string "foo"
      t.timestamps null: false
    end
  end

  it "respects the additional options" do
    expect(WithOptions.columns.map(&:name)).not_to include("id")
  end
end

describe "with_model supports Single Table Inheritance" do
  with_model :Sandwich do
    table do |t|
      t.string "type"
      t.string "bread"
    end
  end

  with_model :ChunkyBacon, superclass: :Sandwich do
    table(false)
  end

  it "shares the superclass's table" do
    expect(ChunkyBacon.table_name).to eq Sandwich.table_name
  end

  it "stores its own type" do
    sandwich = ChunkyBacon.create!(bread: "rye")

    expect(sandwich.reload.type).to eq "ChunkyBacon"
    expect(Sandwich.first).to be_a ChunkyBacon
  end
end

describe "with_model supports foreign keys" do
  with_model :Author do
    table
  end

  with_model :Book do
    table do |t|
      t.references :author, foreign_key: {to_table: Author.table_name}
    end

    model do
      belongs_to :author
    end
  end

  it "has a foreign key" do
    expect { Book.create!(author_id: 0) }
      .to raise_error ActiveRecord::InvalidForeignKey
  end
end
