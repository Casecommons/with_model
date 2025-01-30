# frozen_string_literal: true

require "spec_helper"

describe "Descendants tracking" do # rubocop:disable RSpec/DescribeClass
  with_model :BlogPost do
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
      expect(ActiveSupport::DescendantsTracker.clear_disabled).to be_falsey
      expect { ActiveSupport::DescendantsTracker.clear([]) }.not_to raise_exception
    end

    include_examples "clearing descendants between test runs"
  end

  context "without ActiveSupport::DescendantsTracker (cache_classes: false)" do
    before do
      ActiveSupport::DescendantsTracker.disable_clear!
      expect(ActiveSupport::DescendantsTracker.clear_disabled).to be_truthy
      expect { ActiveSupport::DescendantsTracker.clear([]) }.to raise_exception(RuntimeError)
    end

    include_examples "clearing descendants between test runs"
  end
end
