# frozen_string_literal: true

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

require "minitest/test_task"
Minitest::TestTask.create

# standard rake task
require "standard/rake"

task default: %i[spec test standard]
