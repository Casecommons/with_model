# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'with_model/version'

Gem::Specification.new do |spec|
  spec.name        = 'with_model'
  spec.version     = WithModel::VERSION
  spec.authors     = ['Case Commons, LLC', 'Grant Hutchins']
  spec.email       = ['casecommons-dev@googlegroups.com', 'gems@nertzy.com', 'andrew@johnandrewmarshall.com']
  spec.homepage    = 'https://github.com/Casecommons/with_model'
  spec.summary     = %q(Dynamically build a model within an RSpec context)
  spec.description = spec.summary
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'activerecord', '>= 3.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
