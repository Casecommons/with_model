require "active_record"
require "with_model"

if defined?(RSpec)
  # For RSpec 2 users.
  RSpec.configure do |config|
    config.extend WithModel
  end
else
  # For RSpec 1 users.
  Spec::Runner.configure do |config|
    config.extend WithModel
  end
end

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")
