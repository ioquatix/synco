# frozen_string_literal: true

require_relative "lib/synco/version"

Gem::Specification.new do |spec|
	spec.name = "synco"
	spec.version = Synco::VERSION
	
	spec.summary = "Synco is a tool for scripted synchronization and backups."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/ioquatix/synco"
	
	spec.metadata = {
		"documentation_uri" => "https://ioquatix.github.io/synco/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/ioquatix/synco.git",
	}
	
	spec.files = Dir.glob(["{bin,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["synco"]
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "build-files", "~> 1.0"
	spec.add_dependency "fingerprint", "~> 3.0"
	spec.add_dependency "lockfile"
	spec.add_dependency "mapping", "~> 1.0"
	spec.add_dependency "periodical", "~> 1.1"
	spec.add_dependency "process-group", "~> 1.1"
	spec.add_dependency "samovar", "~> 2.0"
end
