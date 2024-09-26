# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

require_relative "../method"

module Synco
	module Methods
		class ZFS < Method
			def default_command
				["zfs", "-rnv"]
			end
			
			def call(scope, arguments: [])
				from_server = scope.current_server
				master_server = scope.master_server
				target_server = scope.target_server
				directory = scope.directory
				
				send_command = [
					*@command,
					"send",
					master_server.full_path(directory)
				]
				
				receive_command = [
					*@command,
					"receive",
					target_server.full_path(directory)
				]
				
				input, output = IO.pipe
				
				Fiber.new do
					master_server.run(*send_command, out: output, from: from_server)
					output.close
				end.resume
				
				target_server.run(*receive_command, in: input, from: from_server)
				input.close
			end
		end
	end
end
