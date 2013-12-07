require 'bundler'
Bundler.setup

begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end

require 'with_model'
RSpec.configure do |config|
  config.extend WithModel
end

is_jruby = RUBY_PLATFORM =~ /\bjava\b/
adapter = is_jruby ? 'jdbcsqlite3' : 'sqlite3'

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => adapter, :database => ':memory:')

if ENV['LOGGER']
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout)
end
