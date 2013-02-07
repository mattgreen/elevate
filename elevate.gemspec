# -*- encoding: utf-8 -*-
require File.expand_path('../lib/elevate/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matt Green"]
  gem.email         = ["mattgreenrocks@gmail.com"]
  gem.description   = "DESCRIPTION"
  gem.summary       = "SUMMARY"
  gem.homepage      = "http://github.com/mattgreen/elevate"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "elevate"
  gem.require_paths = ["lib"]
  gem.version       = Elevate::VERSION

  gem.add_dependency "motion-cocoapods", ">= 1.2.1"

  gem.add_development_dependency 'rake', '>= 0.9.0'
  gem.add_development_dependency 'guard-motion', '~> 0.1.1'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9.1'
  gem.add_development_dependency 'webstub', '~> 0.3.3'
end
