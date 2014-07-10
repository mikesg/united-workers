# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'united_workers/version'

Gem::Specification.new do |spec|
  spec.name          = "united-workers"
  spec.version       = UnitedWorkers::VERSION
  spec.authors       = ["Mike Grigorov"]
  spec.email         = ["mikesg@abv.bg"]
  spec.summary       = %q{Infrastructure for workers that run task groups.}
  spec.description   = %q{Spawning new workers when a worker killed, run a task after all tasks from a group is completed, etc.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
