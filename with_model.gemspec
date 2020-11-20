# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'with_model/version'

Gem::Specification.new do |spec|
  spec.name        = 'with_model'
  spec.version     = WithModel::VERSION
  spec.authors     = ['Case Commons, LLC', 'Grant Hutchins', 'Andrew Marshall']
  spec.email       = %w[casecommons-dev@googlegroups.com gems@nertzy.com andrew@johnandrewmarshall.com]
  spec.homepage    = 'https://github.com/Casecommons/with_model'
  spec.summary     = 'Dynamically build a model within an RSpec context'
  spec.description = spec.summary
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r(^exe/)) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'activerecord', '>= 5.2', '< 6.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.57'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    spec.add_development_dependency 'sqlite3'
  end
end
