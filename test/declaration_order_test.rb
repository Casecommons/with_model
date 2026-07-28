# frozen_string_literal: true

require "test_helper"

# Models are created in declaration order and destroyed in reverse, so each one
# can depend on the ones above it for as long as it exists. Both halves of that
# are tested here.
#
# The model block is evaluated when the model is created, so a model that
# refers to another one by constant can only work if the model it refers to
# was created first.
class DeclarationOrderTest < Minitest::Test
  with_model :Author do
    table do |t|
      t.string "name"
    end
  end

  with_model :Book do
    table do |t|
      t.integer "author_id"
    end

    model do
      belongs_to :author, class_name: Author.name
    end
  end

  with_model :Shelf do
    table do |t|
      t.string "name"
    end
  end

  # `to_table` because `foreign_key: true` would infer a table name from the
  # column rather than asking the model, and with_model's table names are
  # generated.
  with_model :Jar do
    table do |t|
      t.references "shelf", foreign_key: {to_table: Shelf.table_name}
    end
  end

  def test_a_model_can_refer_to_one_declared_above_it
    author = Author.create!(name: "Ursula K. Le Guin")
    book = Book.create!(author: author)

    assert_equal author, book.reload.author
  end

  # The assertion for teardown order is that this test finishes cleanly. A
  # referenced table cannot be dropped while a row still points at it, so tearing
  # these down in declaration order raises ActiveRecord::InvalidForeignKey after
  # the body has already passed.
  def test_a_table_can_point_at_one_declared_above_it
    shelf = Shelf.create!(name: "pantry")
    jar = Jar.create!(shelf_id: shelf.id)

    assert_equal shelf.id, jar.reload.shelf_id
  end
end
