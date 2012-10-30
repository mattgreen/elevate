# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["AUTHOR"]
  gem.email         = ["EMAIL"]
  gem.description   = "DESCRIPTION"
  gem.summary       = "SUMMARY"
  gem.homepage      = "URL"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sample"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.0"
end
