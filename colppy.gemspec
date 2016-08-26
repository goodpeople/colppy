# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "colppy/version"

Gem::Specification.new do |spec|
  spec.name          = "colppy"
  spec.version       = Colppy::VERSION
  spec.authors       = ["Agustin Cavilliotti"]
  spec.email         = ["cavi21@gmail.com"]

  spec.summary       = "Client to interact with Colppy API"
  spec.description   = "Allow to interact with the services available on the Colppy API (https://colppy.atlassian.net/wiki/display/CA/Bienvenidos+-+Colppy+API)"
  spec.homepage      = "https://github.com/goodpeople/colppy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", [">= 0.8", "< 0.10"]
  spec.add_dependency "multi_json", "~> 1.3"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "httplog"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
