# frozen_string_literal: true

require "test_unit_helper"

# A `table(false)` model that is its own base class and names an existing table
# rather than inheriting one. `with_table` is declared first, so the table is
# created before the model and dropped after it.
class TestUnitOwnTableNameTest < Test::Unit::TestCase
  with_table :test_unit_mythical_beasts do |t|
    t.string "name"
  end

  with_model :TestUnitHippogriff do
    table(false)

    model do
      self.table_name = "test_unit_mythical_beasts"
    end
  end

  def test_the_model_uses_the_table_it_names
    TestUnitHippogriff.create!(name: "Buckbeak")

    assert_equal "test_unit_mythical_beasts", TestUnitHippogriff.table_name
    assert_equal 1, TestUnitHippogriff.count
  end

  def test_the_model_creates_no_table_of_its_own
    assert_empty ActiveRecord::Base.connection.tables.grep(/with_model_test_unit_hippogriff/)
  end
end

# A `table(false)` model that is its own base class and uses the table Active
# Record names after it, without naming it in the model block.
class TestUnitConventionalTableNameTest < Test::Unit::TestCase
  with_table :test_unit_unicorns do |t|
    t.string "name"
  end

  with_model :TestUnitUnicorn do
    table(false)
  end

  def test_the_model_uses_the_table_named_after_it
    TestUnitUnicorn.create!(name: "Charlie")

    assert_equal "test_unit_unicorns", TestUnitUnicorn.table_name
    assert_equal 1, TestUnitUnicorn.count
  end
end

# A `table(false)` model whose superclass is abstract and, needing no table, is
# declared with `table(false)` too.
class TestUnitAbstractSuperclassTableNameTest < Test::Unit::TestCase
  with_table :test_unit_winged_horses do |t|
    t.string "name"
  end

  with_model :TestUnitFlyingCreature do
    table(false)

    model do
      self.abstract_class = true
    end
  end

  with_model :TestUnitPegasus, superclass: :TestUnitFlyingCreature do
    table(false)

    model do
      self.table_name = "test_unit_winged_horses"
    end
  end

  def test_the_model_uses_the_table_it_names
    TestUnitPegasus.create!(name: "Bellerophon")

    assert_equal "test_unit_winged_horses", TestUnitPegasus.table_name
    assert_equal 1, TestUnitPegasus.count
  end
end
