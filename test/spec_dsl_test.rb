# frozen_string_literal: true

require "test_helper"

# The README offers Minitest::Spec as well as Minitest::Test. Minitest::Spec
# inherits from Minitest::Test, so extending Minitest::Test reaches describe
# blocks too, and with_model needs no separate wiring for them.
describe "with_model in a spec-style suite" do
  with_model :Sofa do
    table do |t|
      t.string "type"
      t.string "fabric"
    end
  end

  with_model :Loveseat, superclass: :Sofa do
    table(false)
  end

  it "creates the models a describe block declares" do
    assert_empty Sofa.all, "another test's rows outlived it"

    Loveseat.create!(fabric: "tweed")

    assert_equal Sofa.table_name, Loveseat.table_name
    assert_instance_of Loveseat, Sofa.first
  end

  # Every describe is its own subclass of the one around it, so a nested block
  # inherits the models declared above it and can add more of its own.
  describe "and a nested describe" do
    with_model :Ottoman do
      table do |t|
        t.string "name"
      end
    end

    it "sees the models from both levels" do
      assert_empty Sofa.all, "another test's rows outlived it"

      Ottoman.create!(name: "pouf")
      Loveseat.create!(fabric: "velvet")

      assert_equal 1, Ottoman.count
      assert_equal 1, Sofa.count
    end
  end
end
