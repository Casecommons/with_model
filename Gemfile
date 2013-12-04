source 'https://rubygems.org'

gemspec

gem 'activerecord', :github => 'rails', :branch => ENV['ACTIVE_RECORD_BRANCH'] if ENV['ACTIVE_RECORD_BRANCH']
gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
gem 'activerecord-jdbcsqlite3-adapter', :platforms => :jruby
gem 'coveralls', :require => false, :platform => :mri_20
gem 'rake'
gem 'rdoc'
gem 'sqlite3', :platforms => :ruby
