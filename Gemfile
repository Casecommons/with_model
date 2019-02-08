# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'lint-config-ruby', git: 'https://github.com/Casecommons/lint-config-ruby.git', tag: 'v1.0.0'

ar_branch = ENV['ACTIVE_RECORD_BRANCH']
ar_version = ENV['ACTIVE_RECORD_VERSION']

if ar_branch
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ar_branch
elsif ar_version
  gem 'activerecord', ar_version # rubocop:disable Bundler/DuplicatedGem
end
