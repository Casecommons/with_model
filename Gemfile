# frozen_string_literal: true

source "https://rubygems.org"

gemspec

ar_branch = ENV.fetch("ACTIVE_RECORD_BRANCH", nil)
ar_version = ENV.fetch("ACTIVE_RECORD_VERSION", nil)

if ar_branch
  gem "activerecord", git: "https://github.com/rails/rails.git", branch: ar_branch
elsif ar_version
  gem "activerecord", ar_version
end

gem "bigdecimal"
gem "bundler"
gem "debug"
gem "logger"
gem "minitest"
gem "mutex_m"
gem "rake"
gem "rspec"
gem "ruby-lsp"
gem "sqlite3"
gem "standard"
gem "test-unit"
