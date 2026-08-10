# frozen_string_literal: true

require "spec_helper"

describe "Descendants tracking" do
  with_model :BlogPost do
    table
    model do
      def self.inspect
        "BlogPost class #{object_id}"
      end
    end
  end

  def blog_post_classes
    ActiveRecord::Base.descendants.select do |c|
      c.table_name == BlogPost.table_name
    end
  end

  shared_examples "clearing descendants between test runs" do
    it "includes the correct model class in descendants on the first test run" do
      expect(blog_post_classes).to eq [BlogPost]
    end

    it "includes the correct model class in descendants on the second test run" do
      expect(blog_post_classes).to eq [BlogPost]
    end
  end

  context "with ActiveSupport::DescendantsTracker (cache_classes: true)" do
    before do
      expect { ActiveSupport::DescendantsTracker.clear([]) }.not_to raise_exception
    end

    include_examples "clearing descendants between test runs"
  end

  context "without ActiveSupport::DescendantsTracker (cache_classes: false)" do
    before do
      ActiveSupport::DescendantsTracker.disable_clear!
      expect { ActiveSupport::DescendantsTracker.clear([]) }.to raise_exception(RuntimeError)
    end

    include_examples "clearing descendants between test runs"
  end

  it "keeps filtering ahead of later class method extensions" do
    raw_subclasses = Class.instance_method(:subclasses).super_method
    raw_descendants = Class.instance_method(:descendants).super_method
    override = Module.new do
      define_method(:subclasses) { raw_subclasses.bind_call(self) }
      define_method(:descendants) { raw_descendants.bind_call(self) }
    end
    destroyed_model = stub_const("DestroyedModel", Class.new(ActiveRecord::Base))
    WithModel::DescendantsTracker.clear([destroyed_model])

    ActiveRecord::Base.extend override

    expect(ActiveRecord::Base.descendants).not_to include(destroyed_model)
  ensure
    override&.module_eval do
      remove_method :subclasses
      remove_method :descendants
    end
  end
end
