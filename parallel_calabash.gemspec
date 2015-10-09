# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parallel_calabash/version'

Gem::Specification.new do |spec|
  spec.name          = "parallel_calabash"
  spec.version       = ParallelCalabash::VERSION
  spec.authors       = ["Rajdeep"]
  spec.email         = ["mail.rajvarma@gmail.com"]
  spec.summary       = %q{calabash android tests in parallel}
  spec.description   = %q{Run different calabash android and iOS tests in parallel on different devices and simulators}
  spec.homepage      = "https://github.com/rajdeepv/parallel_calabash"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency 'parallel'
end
