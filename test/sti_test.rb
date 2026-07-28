# frozen_string_literal: true

require "test_helper"

# Stands in for an application's own model, the usual reason to want single table
# inheritance: its table is created once and outlives every test here, so a
# with_model child's rows cannot be disposed of by dropping the table.
module AppModels
  class Cupboard < ActiveRecord::Base
  end
end

ActiveRecord::Base.connection.create_table AppModels::Cupboard.table_name, force: true do |t|
  t.string "type"
  t.string "name"
end

# A with_model parent and an STI child in the same test case. The child's
# superclass is resolved per-example, so this only works if the parent is
# created before the child and destroyed after it.
class StiTest < Minitest::Test
  with_model :Vehicle do
    table do |t|
      t.string "type"
      t.string "name"
    end
  end

  with_model :Truck, superclass: -> { Vehicle } do
    table(false)
  end

  with_model :Chest, superclass: "AppModels::Cupboard" do
    table(false)
  end

  def test_the_child_shares_the_parents_table
    assert_equal Vehicle.table_name, Truck.table_name
  end

  def test_the_child_stores_its_own_type
    truck = Truck.create!(name: "Ford F-150")

    assert_equal "Truck", truck.reload.type
    assert_instance_of Truck, Vehicle.first
  end

  # Rows in a table the child does not own have to be deleted when it goes away,
  # since nothing else will: Cupboard's table is still standing afterwards, and a
  # row naming a class that no longer exists makes it unloadable. Both tests write
  # one and first insist the table is empty, so whichever minitest happens to run
  # second fails if the rows survived teardown - whatever order the seed picks.
  def test_the_childs_rows_do_not_outlive_it
    assert_empty AppModels::Cupboard.all, "a previous test's rows outlived it"

    Chest.create!(name: "sideboard")

    assert_equal 1, AppModels::Cupboard.count
  end

  def test_the_childs_rows_leave_the_superclass_loadable
    assert_empty AppModels::Cupboard.all, "a previous test's rows outlived it"

    Chest.create!(name: "wardrobe")

    assert_instance_of Chest, AppModels::Cupboard.first
  end
end
