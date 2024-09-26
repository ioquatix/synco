# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

require_relative "../method"

module Synco
	module Methods
		class SCP < Method
			def default_command
				["scp", "-pr"]
			end
			
			def call(scope)
				server = scope.current_server
				directory = scope.directory
				
				server.run(
					*@command,
					*arguments,
					# If the destination directory already exists, scp will create the source directory inside the destinatio directory. This behaviour means that running scp multiple times gives different results, i.e. the first time it will copy source/* to destination/*, but the second time you will end up with destination/source/*. Putting a dot after the first path alleviates this issue for some reason.
					scope.master_server.connection_string(directory, on: server) + ".",
					scope.target_server.connection_string(directory, on: server)
				)
			end
		end
	end
end
