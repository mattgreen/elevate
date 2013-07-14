# -*- encoding: utf-8 -*-
require File.expand_path('../lib/elevate/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matt Green"]
  gem.email         = ["mattgreenrocks@gmail.com"]
  gem.description   = "Distill the essence of your RubyMotion app"
  gem.summary       = "Distill the essence of your RubyMotion app"
  gem.homepage      = "http://github.com/mattgreen/elevate"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "elevate"
  gem.require_paths = ["lib"]
  gem.license       = 'MIT'
  gem.version       = Elevate::VERSION

  gem.add_development_dependency 'rake', '>= 0.9.0'
  gem.add_development_dependency 'webstub', '~> 0.6.0'
end
