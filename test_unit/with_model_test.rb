# frozen_string_literal: true

require "test_unit_helper"

class TestUnitWithModelTest < Test::Unit::TestCase
  with_model :TestUnitBlogPost do
    table { |t| t.string "title" }
    model { define_method(:fancy_title) { "Title: #{title}" } }
  end

  with_table :test_unit_widgets do |t|
    t.string "name"
  end

  def test_creates_a_temporary_active_record_model
    record = TestUnitBlogPost.create!(title: "New blog post")

    assert_equal "New blog post", record.reload.title
  end

  def test_defines_model_methods
    assert_equal "Title: New blog post", TestUnitBlogPost.new(title: "New blog post").fancy_title
  end

  def test_defines_the_model_constant
    assert_kind_of Class, TestUnitBlogPost
  end

  def test_creates_a_temporary_table
    assert_true ActiveRecord::Base.connection.data_source_exists?("test_unit_widgets")
  end
end

class TestUnitPerDeclarationRunnerTest < Test::Unit::TestCase
  with_model :TestUnitPerDeclarationModel, runner: :test_unit do
    table
  end

  def test_supports_a_test_unit_runner_override
    assert_kind_of Class, TestUnitPerDeclarationModel
  end
end

class TestUnitRunnerValidationTest < Test::Unit::TestCase
  def test_names_all_supported_runners_for_an_unsupported_runner
    error = assert_raise(ArgumentError) do
      Class.new(Test::Unit::TestCase) do
        extend WithModel

        with_model :UnsupportedTestUnitModel, runner: :unsupported do
          table
        end
      end
    end

    assert_equal "Unsupported test runner set, expected :rspec, :minitest, or :test_unit", error.message
  end
end
