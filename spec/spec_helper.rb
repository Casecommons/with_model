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

  config.warnings = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end

is_jruby = RUBY_PLATFORM =~ /\bjava\b/
adapter = is_jruby ? 'jdbcsqlite3' : 'sqlite3'

# WithModel requires ActiveRecord::Base.connection to be established.
# If ActiveRecord already has a connection, as in a Rails app, this is unnecessary.
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => adapter, :database => ':memory:')

if defined?(I18n) && I18n.respond_to?(:enforce_available_locales=)
  I18n.enforce_available_locales = true
end

if ENV['LOGGER']
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout)
end

module SpecHelper
  module RailsTestCompatability
    if ::ActiveRecord::VERSION::STRING >= '4.1.0'
      require 'minitest'
      include Minitest::Assertions
      def assertions; @assertions ||= 0; end
      def assertions= value; @assertions = value; end
    else
      require 'test/unit/assertions'
      include Test::Unit::Assertions
    end
  end
end
