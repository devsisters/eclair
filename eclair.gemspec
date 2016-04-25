# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eclair/version'

Gem::Specification.new do |spec|
  spec.name          = "ecl"
  spec.version       = Eclair::VERSION
  spec.authors       = ["Devsisters"]
  spec.email         = ["se@devsisters.com"]

  spec.summary       = %q{EC2 ssh helper}
  spec.description   = %q{Simple ssh helper for Amazon EC2}
  spec.homepage      = "https://github.com/devsisters/eclair"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "curses", "~> 1.0"
  spec.add_runtime_dependency "ruby-string-match-scorer", "~> 0.1"
  spec.add_runtime_dependency "pry", "~> 0.10"
end
