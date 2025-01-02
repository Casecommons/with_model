# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'minitest/test_task'
Minitest::TestTask.create

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec test rubocop]
