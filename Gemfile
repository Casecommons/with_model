source 'https://rubygems.org'

gemspec

ar_branch = ENV['ACTIVE_RECORD_BRANCH']
ar_version = ENV['ACTIVE_RECORD_VERSION']

if ar_branch
  gem 'activerecord', :git => 'https://github.com/rails/rails.git', :branch => ar_branch
  gem 'arel', :git => 'https://github.com/rails/arel.git' if ar_branch == 'master'
end

if ar_version
  gem 'activerecord', ar_version
end
