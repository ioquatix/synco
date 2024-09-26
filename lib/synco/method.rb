# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008-2024, by Samuel Williams.

require "fileutils"
require "pathname"
require_relative "controller"

module Synco
	SNAPSHOT_NAME = "latest.snapshot"
	LATEST_NAME = "latest"
	BACKUP_NAME = "%Y.%m.%d-%H.%M.%S"
	BACKUP_TIMEZONE = "UTC"
	
	# A backup method provides the interface to copy data from one system to another.
	class Method < Controller
		def initialize(*command, arguments: [], **options)
			super()
			
			@command = command.empty? ? default_command : command
			@arguments = arguments
			@options = options
		end
		
		attr :options
		attr :arguments
		
		def call(scope, arguments: [])
			server = scope.current_server
			directory = scope.directory
			
			server.run(
				*@command,
				*arguments,
				scope.master_server.connection_string(directory, on: server),
				scope.target_server.connection_string(directory, on: server)
			)
		end
	end
end
