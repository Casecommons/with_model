# frozen_string_literal: true

# rubocop:disable Bundler/DuplicatedGem, Bundler/OrderedGems

source 'https://rubygems.org'

gemspec

gem 'lint-config-ruby', git: 'https://github.com/Casecommons/lint-config-ruby.git', tag: 'v1.0.0'

ar_branch = ENV['ACTIVE_RECORD_BRANCH']
ar_version = ENV['ACTIVE_RECORD_VERSION']
is_jruby = RUBY_PLATFORM == 'java'

if ar_branch
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ar_branch
  if ar_branch == 'master'
    gem 'arel', git: 'https://github.com/rails/arel.git'
    gem 'activerecord-jdbcsqlite3-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter.git' if is_jruby
  end
elsif ar_version
  gem 'activerecord', ar_version # rubocop:disable Bundler/DuplicatedGem
  if is_jruby && Gem::Requirement.new(ar_version).satisfied_by?(Gem::Version.new('6.0.0'))
    gem 'activerecord-jdbcsqlite3-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter.git'
  end
end
