# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new

desc 'Run lint'
RuboCop::RakeTask.new

namespace 'doc' do
  desc 'Generate README and preview in browser'
  task 'readme' do
    sh 'markdown README.md > README.html && open README.html'
  end
end

task default: %i[spec rubocop]
