# frozen_string_literal: true

require "test_helper"

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

  def test_a_model_can_refer_to_one_declared_above_it
    author = Author.create!(name: "Ursula K. Le Guin")
    book = Book.create!(author: author)

    assert_equal author, book.reload.author
  end
end
