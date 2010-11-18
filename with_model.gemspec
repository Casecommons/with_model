# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "with_model/version"

Gem::Specification.new do |s|
  s.name        = "with_model"
  s.version     = WithModel::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Peter Jaros", "Grant Hutchins"]
  s.email       = ["pjaros@pivotallabs.com", "grant@pivotallabs.com"]
  s.homepage    = "https://github.com/casebook/with_model"
  s.summary     = %q{Dynamically build a model within an Rspec context}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>=2.3.5', '<4.0.0'
end
