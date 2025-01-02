# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

ar_branch = ENV.fetch('ACTIVE_RECORD_BRANCH', nil)
ar_version = ENV.fetch('ACTIVE_RECORD_VERSION', nil)

if ar_branch
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ar_branch
  gem 'arel', git: 'https://github.com/rails/arel.git' if ar_branch == 'master'
elsif ar_version
  gem 'activerecord', ar_version
end

gem 'bigdecimal'
gem 'bundler'
gem 'debug'
gem 'minitest'
gem 'mutex_m'
gem 'rake'
gem 'rspec'
gem 'rubocop'
gem 'rubocop-minitest'
gem 'rubocop-rake'
gem 'rubocop-rspec'

if ar_branch == '7-0-stable' || ar_version == '~> 7.0.0'
  gem 'sqlite3', '< 2'
else
  gem 'sqlite3'
end
