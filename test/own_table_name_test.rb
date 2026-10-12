# frozen_string_literal: true

require "test_helper"

# A `table(false)` model that is its own base class and names an existing table
# rather than inheriting one. `with_table` is declared first, so the table is
# created before the model and dropped after it.
class OwnTableNameTest < Minitest::Test
  with_table :mythical_beasts do |t|
    t.string "name"
  end

  with_model :Hippogriff do
    table(false)

    model do
      self.table_name = "mythical_beasts"
    end
  end

  def test_the_model_uses_the_table_it_names
    Hippogriff.create!(name: "Buckbeak")

    assert_equal "mythical_beasts", Hippogriff.table_name
    assert_equal 1, Hippogriff.count
  end

  def test_the_model_creates_no_table_of_its_own
    assert_empty ActiveRecord::Base.connection.tables.grep(/with_model_hippogriff/)
  end
end

# A `table(false)` model that is its own base class and uses the table Active
# Record names after it, without naming it in the model block.
class ConventionalTableNameTest < Minitest::Test
  with_table :unicorns do |t|
    t.string "name"
  end

  with_model :Unicorn do
    table(false)
  end

  def test_the_model_uses_the_table_named_after_it
    Unicorn.create!(name: "Charlie")

    assert_equal "unicorns", Unicorn.table_name
    assert_equal 1, Unicorn.count
  end
end

# A `table(false)` model whose superclass is abstract and, needing no table, is
# declared with `table(false)` too.
class AbstractSuperclassTableNameTest < Minitest::Test
  with_table :winged_horses do |t|
    t.string "name"
  end

  with_model :FlyingCreature do
    table(false)

    model do
      self.abstract_class = true
    end
  end

  with_model :Pegasus, superclass: :FlyingCreature do
    table(false)

    model do
      self.table_name = "winged_horses"
    end
  end

  def test_the_model_uses_the_table_it_names
    Pegasus.create!(name: "Bellerophon")

    assert_equal "winged_horses", Pegasus.table_name
    assert_equal 1, Pegasus.count
  end
end
