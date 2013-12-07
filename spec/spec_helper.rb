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

if defined?(ActiveModel)
  shared_examples_for "ActiveModel" do
    require 'test/unit/assertions'
    require 'active_model/lint'
    include Test::Unit::Assertions
    include ActiveModel::Lint::Tests

    active_model_methods = ActiveModel::Lint::Tests.public_instance_methods
    active_model_lint_tests = active_model_methods.map(&:to_s).grep(/^test/)

    active_model_lint_tests.each do |method_name|
      friendly_name = method_name.gsub('_', ' ')
      example friendly_name do
        begin
          public_send method_name.to_sym
        rescue
          puts $!.message
        end
      end
    end

    before { @model = subject }
  end
end

if ENV['LOGGER']
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout)
end
