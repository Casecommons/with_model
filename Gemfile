source 'https://rubygems.org'

gemspec

if ar_branch = ENV['ACTIVE_RECORD_BRANCH']
  gem 'activerecord', :git => 'https://github.com/rails/rails.git', :branch => ENV['ACTIVE_RECORD_BRANCH']
  gem 'arel', :git => 'https://github.com/rails/arel.git' if ar_branch == 'master'
end

if ENV['ACTIVE_RECORD_VERSION']
  gem 'activerecord', ENV['ACTIVE_RECORD_VERSION']
end
