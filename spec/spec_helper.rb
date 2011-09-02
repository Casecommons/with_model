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

# For readme_spec.rb
module SomeModule; end

if defined?(ActiveModel)
  shared_examples_for "ActiveModel" do
    require 'test/unit/assertions'
    require 'active_model/lint'
    include Test::Unit::Assertions
    include ActiveModel::Lint::Tests

    # to_s is to support ruby-1.9
    ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
      example m.gsub('_',' ') do
        begin
          send m
        rescue
          puts $!.message
        end
      end
    end

    before { @model = subject }
  end
end

if ENV["LOGGER"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end
