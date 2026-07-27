# frozen_string_literal: true

require "with_model/invalid_superclass"

module WithModel
  # Raised when the name given for a `superclass:` resolves to nothing at all.
  #
  # A kind of {WithModel::InvalidSuperclass}, so every superclass that cannot be
  # used is catchable in one place, while a name that is simply not there - a
  # typo, or a with_model superclass declared after the models inheriting it -
  # can be told apart from a class that exists but cannot supply a table.
  class MissingSuperclass < InvalidSuperclass
  end
end
