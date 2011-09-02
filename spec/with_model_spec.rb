require 'spec_helper'

describe "a temporary ActiveRecord model created with with_model" do
  non_shadowing_example_ran = false

  describe "which doesn't shadow an existing class" do
    with_model :BlogPost do
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

    after do
      non_shadowing_example_ran = true
    end

    it "should act like a normal ActiveRecord model" do
      record = BlogPost.create!(:title => 'New blog post', :content => "Hello, world!")

      record.reload

      record.title.should == 'New blog post'
      record.content.should == 'Hello, world!'
      record.updated_at.should be_present

      record.destroy

      lambda {
        record.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    if defined?(ActiveModel)
      describe "the class" do
        subject { BlogPost.new }
        it_should_behave_like "ActiveModel"
      end
    end

    it "should have methods defined in its model block" do
      BlogPost.new(:title => 'New blog post').fancy_title.should == "Title: New blog post"
    end

    it "should define a constant" do
      BlogPost.should be_a(Class)
    end

    describe ".with_model?" do
      it "should return true" do
        BlogPost.with_model?.should be_true
      end
    end

    it "should have a base_class of itself" do
      BlogPost.base_class.should == BlogPost
    end
  end

  context "after an example which uses with_model without shadowing an existing constant" do
    it "should return the constant to its undefined state" do
      non_shadowing_example_ran.should be_true
      defined?(BlogPost).should be_false
    end
  end

  ::MyConst = 1

  shadowing_example_ran = false

  describe "that shadows an existing constant" do
    with_model :MyConst do
    end

    after do
      shadowing_example_ran = true
    end

    it "should shadow that constant" do
      MyConst.should be_a(Class)
    end
  end

  context "in later examples" do
    it "should return the constant to its original value" do
      shadowing_example_ran.should be_true
      MyConst.should == 1
    end
  end

  describe "with a plural name" do
    with_model :BlogPosts do
    end

    it "should not singularize the constant name" do
      BlogPosts.should be
      lambda { BlogPost }.should raise_error(NameError)
    end
  end

  describe "with a name containing capital letters" do
    with_model :BlogPost do
    end

    it "should tableize the table name" do
      BlogPost.table_name.should match(/_blog_posts_/)
      BlogPost.table_name.should == BlogPost.table_name.downcase
    end
  end

  describe "with a name with underscores" do
    with_model :blog_post do
    end

    it "should constantize the name" do
      BlogPost.should be
    end

    it "should tableize the table name" do
      BlogPost.table_name.should match(/_blog_posts_/)
      BlogPost.table_name.should == BlogPost.table_name.downcase
    end
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

    it "should have the mixin" do
      lambda { ::ModelWithMixin.new.foo }.should_not raise_error
      ::ModelWithMixin.include?(AMixin).should be_true
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

    it "should only have one after_save callback" do
      subject.should_receive(:my_method).once
      subject.save
    end

    it "should still only have one after_save callback in future tests" do
      subject.should_receive(:my_method).once
      subject.save
    end
  end

  if defined?(Mixico)
    context "after a context that uses a mixin" do
      it "should not have the mixin" do
        lambda { ::ModelWithMixin.new.foo }.should raise_error(NoMethodError)
        ::ModelWithMixin.include?(AMixin).should be_false
      end
    end
  end

  context "with table options" do
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

  context "without a model block" do
    with_model :BlogPost do
      table do |t|
        t.string 'title'
        t.text 'content'
        t.timestamps
      end
    end

    it "should act like a normal ActiveRecord model" do
      record = BlogPost.create!(:title => 'New blog post', :content => "Hello, world!")

      record.reload

      record.title.should == 'New blog post'
      record.content.should == 'Hello, world!'
      record.updated_at.should be_present

      record.destroy

      lambda {
        record.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    if defined?(ActiveModel)
      describe "the class" do
        subject { BlogPost.new }
        it_should_behave_like "ActiveModel"
      end
    end

  end

  context "without a table block" do
    with_model :BlogPost do
    end

    it "should act like a normal ActiveRecord model" do
      record = BlogPost.create!
      record.reload
      record.destroy
      lambda {
        record.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    if defined?(ActiveModel)
      describe "the class" do
        subject { BlogPost.new }
        it_should_behave_like "ActiveModel"
      end
    end
  end
end
