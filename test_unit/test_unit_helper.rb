# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "active_record"
require "test/unit"
require "with_model"

WithModel.runner = :test_unit

Test::Unit::TestCase.extend WithModel

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
