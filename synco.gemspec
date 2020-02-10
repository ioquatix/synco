
require_relative 'lib/synco/version'

Gem::Specification.new do |spec|
	spec.name          = "synco"
	spec.version       = Synco::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.summary       = %q{Synco is a tool for scripted synchronization and backups.}
	spec.homepage      = ""
	spec.license       = "MIT"
	
	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	
	spec.add_dependency("periodical", "~> 1.1")
	spec.add_dependency("samovar", "~> 2.0")
	spec.add_dependency("fingerprint", "~> 3.0")
	spec.add_dependency("mapping", "~> 1.0")
	spec.add_dependency("build-files", "~> 1.0")
	spec.add_dependency("process-group", "~> 1.1")
	
	spec.add_dependency("lockfile")
	
	spec.add_development_dependency "covered"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rspec", "~> 3.4"
	spec.add_development_dependency "rake"
end
