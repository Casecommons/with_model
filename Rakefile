require 'bundler'
Bundler::GemHelper.install_tasks

environments = %w[rspec1 rspec2]
major, minor, revision = RUBY_VERSION.split(".").map{|str| str.to_i }

in_environment = lambda do |environment, command|
  sh %Q{export BUNDLE_GEMFILE="gemfiles/#{environment}/Gemfile"; bundle update && bundle exec #{command}}
end

in_all_environments = lambda do |command|
  environments.each do |environment|
    puts "\n---#{environment}---\n"
    in_environment.call(environment, command)
  end
end

autotest_styles = {
  :rspec1 => 'rspec',
  :rspec2 => 'rspec2'
}

desc "Run all specs against Rspec 1 and 2"
task "spec" do
  in_environment.call('rspec1', 'spec spec') if major == 1 && minor < 9
  in_environment.call('rspec2', 'rspec spec')
end

namespace "autotest" do
  environments.each do |environment|
    desc "Run autotest in #{environment}"
    task environment do
      in_environment.call(environment, "autotest -s #{autotest_styles[environment.to_sym]}")
    end
  end
end

namespace "doc" do
  desc "Generate README and preview in browser"
  task "readme" do
    sh "rdoc -c utf8 README.rdoc && open doc/files/README_rdoc.html"
  end
end

task :default => :spec
