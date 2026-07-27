# frozen_string_literal: true

module WithModel
  # Raised when the `superclass:` a model was given cannot be used: it is not an
  # Active Record class at all, or it is one that cannot supply a table to a model
  # which has none of its own - because it has no table itself
  # (`ActiveRecord::Base`, or an abstract class), or because its table has no
  # inheritance column and so cannot tell a subclass's rows apart.
  #
  # An `ArgumentError`, because each is a fact about the argument rather than about
  # when it was looked at, and the superclass is needed the moment the model is
  # built - unlike a table, which an example is free to create later.
  class InvalidSuperclass < ArgumentError
  end
end
