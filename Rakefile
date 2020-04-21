# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'rubocop/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
end

desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
end

desc 'Run lint'
RuboCop::RakeTask.new

namespace 'doc' do
  desc 'Generate README and preview in browser'
  task 'readme' do
    sh 'markdown README.md > README.html && open README.html'
  end
end

task default: %i[spec test rubocop]
