# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Matt Green"]
  gem.email         = ["mattgreenrocks@gmail.com"]
  gem.description   = "DESCRIPTION"
  gem.summary       = "SUMMARY"
  gem.homepage      = "http://github.com/mattgreen/arbiter"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "arbiter"
  gem.require_paths = ["lib"]
  gem.version       = "0.1"
end
