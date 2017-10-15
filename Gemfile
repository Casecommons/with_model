source 'https://rubygems.org'

gemspec

gem 'lint-config-cc', git: 'https://github.com/Casecommons/lint-config-ruby.git'

ar_branch = ENV['ACTIVE_RECORD_BRANCH']
ar_version = ENV['ACTIVE_RECORD_VERSION']

if ar_branch
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ar_branch
  gem 'arel', git: 'https://github.com/rails/arel.git' if ar_branch == 'master'
elsif ar_version
  gem 'activerecord', ar_version # rubocop:disable Bundler/DuplicatedGem
end
