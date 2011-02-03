require 'spec_helper'

describe "ActiveRecord behaviors" do
  describe "a temporary ActiveRecord model created with with_model that has a named_scope" do
    before do
      class RegularModel < ActiveRecord::Base
        scope_method =
          if respond_to?(:scope) && !protected_methods.include?('scope')
            :scope # ActiveRecord 3.x
          else
            :named_scope # ActiveRecord 2.x
          end

        send scope_method, :title_is_foo, :conditions => {:title => 'foo'}
      end
      RegularModel.connection.drop_table(RegularModel.table_name) rescue nil
      RegularModel.connection.create_table(RegularModel.table_name) do |t|
        t.string 'title'
        t.text 'content'
        t.timestamps
      end
    end

    after do
      RegularModel.connection.drop_table(@model.table_name) rescue nil
    end

    with_model :blog_post do
      table do |t|
        t.string 'title'
        t.text 'content'
        t.timestamps
      end

      model do
        scope_method =
          if respond_to?(:scope) && !protected_methods.include?('scope')
            :scope # ActiveRecord 3.x
          else
            :named_scope # ActiveRecord 2.x
          end

        send scope_method, :title_is_foo, :conditions => {:title => 'foo'}
      end
    end

    describe "the named scope" do
      it "should work like a regular named scope" do
        included = RegularModel.create!(:title => 'foo', :content => "Include me!")
        excluded = RegularModel.create!(:title => 'bar', :content => "Include me!")

        RegularModel.title_is_foo.should == [included]

        included = BlogPost.create!(:title => 'foo', :content => "Include me!")
        excluded = BlogPost.create!(:title => 'bar', :content => "Include me!")

        BlogPost.title_is_foo.should == [included]
      end
    end
  end
end
