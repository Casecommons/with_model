# frozen_string_literal: true

require "test_helper"

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

  def test_the_child_shares_the_parents_table
    assert_equal Vehicle.table_name, Truck.table_name
  end

  def test_the_child_stores_its_own_type
    truck = Truck.create!(name: "Ford F-150")

    assert_equal "Truck", truck.reload.type
    assert_instance_of Truck, Vehicle.first
  end
end
