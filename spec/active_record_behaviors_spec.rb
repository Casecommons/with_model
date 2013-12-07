require 'spec_helper'

describe "ActiveRecord behaviors" do
  describe "a temporary ActiveRecord model created with with_model" do
    context "that has a named scope" do
      before do
        regular_model = Class.new ActiveRecord::Base do
          scope :title_is_foo, lambda { where(:title => 'foo') }
        end
        stub_const 'RegularModel', regular_model

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

      with_model :BlogPost do
        table do |t|
          t.string 'title'
          t.text 'content'
          t.timestamps
        end

        model do
          scope :title_is_foo, lambda { where(:title => 'foo') }
        end
      end

      describe "the named scope" do
        it "should work like a regular named scope" do
          included = RegularModel.create!(:title => 'foo', :content => 'Include me!')
          excluded = RegularModel.create!(:title => 'bar', :content => 'Include me!')

          RegularModel.title_is_foo.should == [included]

          included = BlogPost.create!(:title => 'foo', :content => 'Include me!')
          excluded = BlogPost.create!(:title => 'bar', :content => 'Include me!')

          BlogPost.title_is_foo.should == [included]
        end
      end
    end

    context "that has a polymorphic belongs_to" do
      before do
        animal = Class.new ActiveRecord::Base do
          has_many :tea_cups, :as => :pet
        end
        stub_const 'Animal', animal
      end

      with_model :TeaCup do
        table do |t|
          t.belongs_to :pet, :polymorphic => true
        end
        model do
          belongs_to :pet, :polymorphic => true
        end
      end

      with_table :animals

      with_model :StuffedAnimal do
        model do
          has_many :tea_cups, :as => :pet
        end
      end

      describe "the polymorphic belongs_to" do
        it "should work like a regular polymorphic belongs_to" do
          animal = Animal.create!
          stuffed_animal = StuffedAnimal.create!

          tea_cup_for_animal = TeaCup.create!(:pet => animal)
          tea_cup_for_animal.pet_type.should == 'Animal'
          animal.tea_cups.should include(tea_cup_for_animal)

          tea_cup_for_stuffed_animal = TeaCup.create!(:pet => stuffed_animal)
          tea_cup_for_stuffed_animal.pet_type.should == 'StuffedAnimal'
          stuffed_animal.tea_cups.should include(tea_cup_for_stuffed_animal)
        end
      end
    end
  end

  context "with an association" do
    with_model :Province do
      table do |t|
        t.belongs_to :country
      end
      model do
        belongs_to :country
      end
    end

    with_model :Country do
    end

    context "in earlier examples" do
      it "should work as normal" do
        Province.create!(:country => Country.create!)
      end
    end

    context "in later examples" do
      it "should not hold a reference to earlier example groups' classes" do
        Province.reflect_on_association(:country).klass.should == Country
      end
    end
  end
end
