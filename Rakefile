require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new

namespace "doc" do
  desc "Generate README and preview in browser"
  task "readme" do
    sh "markdown README.md > README.html && open README.html"
  end
end

task :default => :spec
