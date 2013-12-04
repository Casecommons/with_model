require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :spec

def bundle_exec(command)
  sh %Q{bundle update && bundle exec #{command}}
end

desc "Run all specs"
task "spec" do
  bundle_exec("rspec spec")
end

namespace "doc" do
  desc "Generate README and preview in browser"
  task "readme" do
    sh "markdown README.md > README.html && open README.html"
  end
end

task :default => :spec
