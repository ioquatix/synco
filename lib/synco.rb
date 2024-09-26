# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008-2024, by Samuel Williams.

require "yaml"
require "socket"
require "set"

require_relative "synco/version"
require_relative "synco/script"
require_relative "synco/scope"

require "fileutils"
require "optparse"

require "lockfile"

module Synco
	# Run a prepared backup script using a lockfile.
	def self.run_script(*arguments, **options, &block)
		script = Synco::Script.build(*arguments, **options, &block)
		lockfile_path = $0 + ".lock"
		
		# script.on(:failure) do |exception|
		# 	logger.error{exception}
		# 	
		# 	raise
		# end
		
		Lockfile.new(lockfile_path, :retries => 0) do
			Runner.new(script).call
		end
	end
end
