# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vebra/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mike Fulcher"]
  gem.email         = ["mike@rawnet.com"]
  gem.description   = %q{An unofficial ruby wrapper for the Vebra API}
  gem.summary       = %q{Ruby wrapper for the Vebra API}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "vebra"
  gem.require_paths = ["lib"]
  gem.version       = Vebra::VERSION

  gem.add_dependency "nokogiri", "~> 1.5.2"
  gem.add_dependency "json", "~> 1.6.5"
end
