# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new

namespace 'doc' do
  desc 'Generate README and preview in browser'
  task 'readme' do
    sh 'markdown README.md > README.html && open README.html'
  end
end

task :codeclimate do
  begin
    sh 'bin/codeclimate-test-reporter' if ENV['CODECLIMATE_REPO_TOKEN']
  rescue StandardError => ex
    puts ex.inspect
  end
end

task default: %i[spec codeclimate]
