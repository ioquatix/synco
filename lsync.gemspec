# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lsync/version'

Gem::Specification.new do |spec|
	spec.name          = "lsync"
	spec.version       = LSync::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.summary       = %q{LSync is a tool for scripted synchronization and backups.}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	s.add_dependency("fingerprint", ">= 1.2.4")
	s.add_dependency("rexec", ">= 1.4.1")
	s.add_dependency("lockfile")

	s.has_rdoc = "yard"

	spec.add_development_dependency "bundler", "~> 1.6"
    spec.add_development_dependency "rspec", "~> 3.0"
	spec.add_development_dependency "rake"
end
