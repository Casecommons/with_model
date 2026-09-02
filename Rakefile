# frozen_string_literal: true

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

require "minitest/test_task"
Minitest::TestTask.create

require "rake/testtask"
Rake::TestTask.new(:test_unit) do |task|
  task.libs << "lib" << "test_unit" << "test"
  task.pattern = "test_unit/**/*_test.rb"
end

# standard rake task
require "standard/rake"

task default: %i[spec test test_unit standard]
