require 'active_model'
require 'spec_helper'

shared_examples_for "ActiveModel" do
  require 'active_model/lint'
  include SpecHelper::RailsTestCompatability
  include ActiveModel::Lint::Tests

  active_model_methods = ActiveModel::Lint::Tests.public_instance_methods
  active_model_lint_tests = active_model_methods.map(&:to_s).grep(/^test/)

  active_model_lint_tests.each do |method_name|
    friendly_name = method_name.gsub('_', ' ')
    example friendly_name do
      public_send method_name.to_sym
    end
  end

  before { @model = subject }
end

describe "a temporary ActiveRecord model created with with_model" do
  non_shadowing_example_ran = false

  describe "which doesn't shadow an existing class" do
    with_model :BlogPost do
      table do |t|
        t.string 'title'
        t.text 'content'
        t.timestamps null: false
      end

      model do
        def fancy_title
          "Title: #{title}"
        end
      end
    end

    after do
      non_shadowing_example_ran = true
    end

    it "acts like a normal ActiveRecord model" do
      record = BlogPost.create!(:title => 'New blog post', :content => 'Hello, world!')

      record.reload

      expect(record.title).to eq 'New blog post'
      expect(record.content).to eq 'Hello, world!'
      expect(record.updated_at).to be_present

      record.destroy

      expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end

    it "has the methods defined in its model block" do
      expect(BlogPost.new(:title => 'New blog post').fancy_title).to eq 'Title: New blog post'
    end

    it "defines a constant" do
      expect(BlogPost).to be_a(Class)
    end

    describe ".with_model?" do
      it "returns true" do
        expect(BlogPost.with_model?).to eq true
      end
    end

    it "is its own base_class" do
      expect(BlogPost.base_class).to eq BlogPost
    end
  end

  context "after an example which uses with_model without shadowing an existing constant" do
    it "returns the constant to its undefined state" do
      expect(non_shadowing_example_ran).to eq true
      expect(defined?(BlogPost)).to be_falsy
    end
  end

  ::MyConst = 1

  shadowing_example_ran = false

  describe "that shadows an existing constant" do
    with_model :MyConst

    after do
      shadowing_example_ran = true
    end

    it "shadows that constant" do
      expect(MyConst).to be_a(Class)
    end
  end

  context "in later examples" do
    it "returns the constant to its original value" do
      expect(shadowing_example_ran).to eq true
      expect(MyConst).to eq 1
    end
  end

  describe "with a plural name" do
    with_model :BlogPosts

    it "does not singularize the constant name" do
      expect(BlogPosts).to be
      expect(lambda { BlogPost }).to raise_error(NameError)
    end
  end

  describe "with a name containing capital letters" do
    with_model :BlogPost

    it "tableizes the table name" do
      expect(BlogPost.table_name).to match(/_blog_posts_/)
      expect(BlogPost.table_name).to eq BlogPost.table_name.downcase
    end
  end

  describe "with a name with underscores" do
    with_model :blog_post

    it "constantizes the name" do
      expect(BlogPost).to be
    end

    it "tableizes the table name" do
      expect(BlogPost.table_name).to match(/_blog_posts_/)
      expect(BlogPost.table_name).to eq BlogPost.table_name.downcase
    end
  end

  describe "using the constant in the model block" do
    with_model :BlogPost do
      model do
        raise 'I am not myself!' unless self == BlogPost
      end
    end

    it "is available" do end
  end

  module AMixin
    def foo
    end
  end

  context "with a mixin" do
    with_model :WithAMixin do
      model do
        include AMixin
      end
    end

    before { ::ModelWithMixin = WithAMixin }

    it "has the mixin" do
      expect(lambda { ::ModelWithMixin.new.foo }).to_not raise_error
      expect(::ModelWithMixin.include?(AMixin)).to eq true
    end
  end

  context "with a mixin that has a class_eval" do
    subject { WithAClassEval.new }

    module AMixinWithClassEval
      def self.included(klass)
        klass.class_eval do
          after_save { |object| object.my_method }
        end
      end
    end

    with_model :WithAClassEval do
      model do
        include AMixinWithClassEval
        def my_method; end
      end
    end

    it "only has one after_save callback" do
      expect(subject).to receive(:my_method).once
      subject.save
    end

    it "still only has one after_save callback in future tests" do
      expect(subject).to receive(:my_method).once
      subject.save
    end
  end

  context "with table options" do
    with_model :WithOptions do
      table :id => false do |t|
        t.string 'foo'
        t.timestamps null: false
      end
    end

    it "respects the additional options" do
      expect(WithOptions.columns.map(&:name)).to_not include('id')
    end
  end

  context "without a block" do
    with_model :BlogPost

    it "acts like a normal ActiveRecord model" do
      record = BlogPost.create!
      record.reload
      record.destroy
      expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end
  end

  context "with an empty block" do
    with_model(:BlogPost) {}

    it "acts like a normal ActiveRecord model" do
      record = BlogPost.create!
      record.reload
      record.destroy
      expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end
  end

  context "without a model block" do
    with_model :BlogPost do
      table do |t|
        t.string 'title'
        t.text 'content'
        t.timestamps null: false
      end
    end

    it "acts like a normal ActiveRecord model" do
      record = BlogPost.create!(:title => 'New blog post', :content => 'Hello, world!')

      record.reload

      expect(record.title).to eq 'New blog post'
      expect(record.content).to eq 'Hello, world!'
      expect(record.updated_at).to be_present

      record.destroy

      expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end
  end

  context "without a table or model block" do
    with_model :BlogPost

    it "acts like a normal ActiveRecord model" do
      expect(BlogPost.columns.map(&:name)).to eq ['id']
      record = BlogPost.create!
      record.reload
      record.destroy
      expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end
  end

  context "with ActiveSupport::DescendantsTracker" do
    with_model :BlogPost

    it "includes the correct model class in descendants on the first test run" do
      descendant = ActiveRecord::Base.descendants.detect do |c|
        c.table_name == BlogPost.table_name
      end
      expect(descendant).to eq BlogPost
    end

    it "includes the correct model class in descendants on the second test run" do
      descendant = ActiveRecord::Base.descendants.detect do |c|
        c.table_name == BlogPost.table_name
      end
      expect(descendant).to eq BlogPost
    end
  end

  context "with_model can be run within RSpec :all hook" do
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

  context "with 'superclass' option" do
    class BlogPostParent < ActiveRecord::Base
      self.abstract_class = true
    end

    with_model :BlogPost, superclass: BlogPostParent do
      table do |t|
        t.string 'title'
      end
    end

    describe "the class" do
      subject { BlogPost.new }
      it_should_behave_like "ActiveModel"
    end

    it "is a subclass of the supplied superclass" do
      expect(BlogPost < BlogPostParent).to eq true
    end

    it "is its own base_class" do
      expect(BlogPost.base_class).to eq BlogPost
    end

    it "responds to .with_model? with true" do
      expect(BlogPost.with_model?).to eq true
    end
  end
end
