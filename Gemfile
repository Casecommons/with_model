source 'https://rubygems.org'

gemspec

gem 'activerecord', :git => 'https://github.com/rails/rails.git', :branch => ENV['ACTIVE_RECORD_BRANCH'] if ENV['ACTIVE_RECORD_BRANCH']
gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
gem 'activerecord-jdbcsqlite3-adapter', :platforms => :jruby
gem 'coveralls', :require => false, :platforms => :mri_20
gem 'sqlite3', '1.3.8', :platforms => :ruby
