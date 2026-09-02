# frozen_string_literal: true

require "test_unit_helper"

# Stands in for an application's own model, the usual reason to want single table
# inheritance: its table is created once and outlives every test here, so a
# with_model child's rows cannot be disposed of by dropping the table.
module TestUnitAppModels
  class Cupboard < ActiveRecord::Base
  end
end

ActiveRecord::Base.connection.create_table TestUnitAppModels::Cupboard.table_name,
  force: true do |t|
  t.string "type"
  t.string "name"
end

# A with_model parent and an STI child in the same test case. The child's
# superclass is resolved per-example, so this only works if the parent is
# created before the child and destroyed after it.
class TestUnitStiTest < Test::Unit::TestCase
  with_model :TestUnitVehicle do
    table do |t|
      t.string "type"
      t.string "name"
    end
  end

  with_model :TestUnitTruck, superclass: -> { TestUnitVehicle } do
    table(false)
  end

  with_model :TestUnitChest, superclass: "TestUnitAppModels::Cupboard" do
    table(false)
  end

  def test_the_child_shares_the_parents_table
    assert_equal TestUnitVehicle.table_name, TestUnitTruck.table_name
  end

  def test_the_child_stores_its_own_type
    truck = TestUnitTruck.create!(name: "Ford F-150")

    assert_equal "TestUnitTruck", truck.reload.type
    assert_instance_of TestUnitTruck, TestUnitVehicle.first
  end

  # Rows in a table the child does not own have to be deleted when it goes away,
  # since nothing else will: Cupboard's table is still standing afterwards, and a
  # row naming a class that no longer exists makes it unloadable. Both tests write
  # one and first insist the table is empty, so whichever test happens to run
  # second fails if the rows survived teardown.
  def test_the_childs_rows_do_not_outlive_it
    assert_empty TestUnitAppModels::Cupboard.all,
      "a previous test's rows outlived it"

    TestUnitChest.create!(name: "sideboard")

    assert_equal 1, TestUnitAppModels::Cupboard.count
  end

  def test_the_childs_rows_leave_the_superclass_loadable
    assert_empty TestUnitAppModels::Cupboard.all,
      "a previous test's rows outlived it"

    TestUnitChest.create!(name: "wardrobe")

    assert_instance_of TestUnitChest, TestUnitAppModels::Cupboard.first
  end
end
