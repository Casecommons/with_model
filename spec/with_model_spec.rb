require 'spec_helper'

describe "a temporary ActiveRecord model created with with_model" do
  non_shadowing_example_ran = false

  describe "which doesn't shadow an existing class" do
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

    after do
      non_shadowing_example_ran = true
    end

    it "should act like a normal ActiveRecord model" do
      record = blog_post.create!(:title => 'New blog post', :content => "Hello, world!")

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

    it "should define a constant" do
      BlogPost.should == @blog_post
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
    with_model :my_const do
      table do
      end
    end

    after do
      shadowing_example_ran = true
    end

    it "should shadow that constant" do
      MyConst.should == my_const
    end
  end

  context "in later examples" do
    it "should return the constant to its original value" do
      shadowing_example_ran.should be_true
      MyConst.should == 1
    end
  end
end
