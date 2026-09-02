# frozen_string_literal: true

require "test_unit_helper"

class TestUnitLifecycleBaseTest < Test::Unit::TestCase
  FIXTURE_EVENTS = []

  with_model :TestUnitLifecycleParent do
    table { |t| t.string "name" }
  end

  def setup
    FIXTURE_EVENTS.clear
    assert_kind_of Class, TestUnitLifecycleParent
    FIXTURE_EVENTS << :inherited_setup
  end

  def teardown
    assert_kind_of Class, TestUnitLifecycleParent
    FIXTURE_EVENTS << :inherited_teardown
  end
end

class TestUnitLifecycleTest < TestUnitLifecycleBaseTest
  with_model :TestUnitLifecycleChild do
    table do |t|
      t.references "parent", foreign_key: {to_table: TestUnitLifecycleParent.table_name}
    end

    model { belongs_to :parent, class_name: TestUnitLifecycleParent.name }
  end

  def setup
    super
    assert_kind_of Class, TestUnitLifecycleChild
    FIXTURE_EVENTS << :local_setup
  end

  def teardown
    assert_kind_of Class, TestUnitLifecycleChild
    FIXTURE_EVENTS << :local_teardown
    super
    return unless name == "test_models_are_available_through_user_fixtures"

    assert_equal [
      :inherited_setup,
      :local_setup,
      :test_body,
      :local_teardown,
      :inherited_teardown
    ], FIXTURE_EVENTS
  end

  def test_models_are_available_through_user_fixtures
    parent = TestUnitLifecycleParent.create!(name: "parent")
    child = TestUnitLifecycleChild.create!(parent: parent)

    assert_equal parent, child.reload.parent
    FIXTURE_EVENTS << :test_body
  end

  def test_model_destruction_unwinds_inheritance_order
    parent_test_case = Class.new(Test::Unit::TestCase) do
      with_model :TestUnitLifecycleOrderParent do
        table
      end
    end
    test_case = Class.new(parent_test_case) do
      teardown(after: :prepend) do
        assert_false Object.const_defined?(:TestUnitLifecycleOrderChild)
        assert_false ActiveRecord::Base.connection.data_source_exists?(child_table_name)
        assert_kind_of Class, TestUnitLifecycleOrderParent
        assert ActiveRecord::Base.connection.data_source_exists?(parent_table_name)
      end

      with_model :TestUnitLifecycleOrderChild do
        table
      end

      define_method(:parent_table_name) { TestUnitLifecycleOrderParent.table_name }
      define_method(:child_table_name) { @child_table_name }
      define_method(:test_lifecycle) { @child_table_name = TestUnitLifecycleOrderChild.table_name }
    end

    result = Test::Unit::TestResult.new
    test_case.new("test_lifecycle").run(result) {}

    assert_equal 1, result.run_count
    assert_equal 0, result.error_count
  end
end

class TestUnitUserHookFailureTest < Test::Unit::TestCase
  def test_setup_error_does_not_prevent_model_cleanup
    test_case = Class.new(Test::Unit::TestCase) do
      class << self
        attr_accessor :created_table_name
      end

      with_model :TestUnitSetupFailureModel do
        table
      end

      def setup
        self.class.created_table_name = TestUnitSetupFailureModel.table_name
        raise "setup failed"
      end

      def test_setup_failure
      end
    end

    result = Test::Unit::TestResult.new
    test_case.new("test_setup_failure").run(result) {}

    assert_hook_failure_cleans_up_model(
      result,
      RuntimeError,
      "setup failed",
      :TestUnitSetupFailureModel,
      test_case.created_table_name
    )
  end

  def test_teardown_error_does_not_prevent_model_cleanup
    test_case = Class.new(Test::Unit::TestCase) do
      class << self
        attr_accessor :created_table_name
      end

      with_model :TestUnitTeardownFailureModel do
        table
      end

      def teardown
        self.class.created_table_name = TestUnitTeardownFailureModel.table_name
        raise "teardown failed"
      end

      def test_teardown_failure
      end
    end

    result = Test::Unit::TestResult.new
    test_case.new("test_teardown_failure").run(result) {}

    assert_hook_failure_cleans_up_model(
      result,
      RuntimeError,
      "teardown failed",
      :TestUnitTeardownFailureModel,
      test_case.created_table_name
    )
  end

  private

  def assert_hook_failure_cleans_up_model(result, error_class, message, constant, table_name)
    assert_equal 1, result.run_count
    assert_equal 1, result.error_count
    assert_equal error_class, result.errors.first.exception.class
    assert_equal message, result.errors.first.exception.message
    assert_false Object.const_defined?(constant)
    assert_false ActiveRecord::Base.connection.data_source_exists?(table_name)
  end
end

class TestUnitPartialModelCreationFailureTest < Test::Unit::TestCase
  def test_preserves_the_setup_error_when_model_creation_does_not_assign_a_model
    test_case = Class.new(Test::Unit::TestCase) do
      with_model :TestUnitPartiallyCreatedModel, superclass: Object do
        table(false)
      end

      def test_setup_failure
      end
    end

    result = Test::Unit::TestResult.new
    test_case.new("test_setup_failure").run(result) {}

    assert_equal 1, result.run_count
    assert_equal 1, result.error_count
    assert_kind_of WithModel::InvalidSuperclass, result.errors.first.exception
  end
end
