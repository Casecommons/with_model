source 'https://rubygems.org'

gemspec

gem 'activerecord-jdbcsqlite3-adapter', :platforms => :jruby
gem 'coveralls', :require => false, :platforms => :mri_20

if ar_branch = ENV['ACTIVE_RECORD_BRANCH']
  gem 'activerecord', :git => 'https://github.com/rails/rails.git', :branch => ENV['ACTIVE_RECORD_BRANCH']
  gem 'arel', :git => 'https://github.com/rails/arel.git' if ar_branch == 'master'
end

if ENV['ACTIVE_RECORD_VERSION']
  gem 'activerecord', ENV['ACTIVE_RECORD_VERSION']
end

case RUBY_ENGINE
when 'ruby'
  gem 'sqlite3', '>= 1.3.10', :platforms => :ruby
when 'rbx'
  gem 'sqlite3', '1.3.8', :platforms => :ruby
end
