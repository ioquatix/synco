# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

require "pathname"

module Synco
	# A shell provides access to a server, typically to run commands.
	class Shell
		def initialize(*command, arguments: [], **options)
			@command = command.empty? ? default_command : command
			
			@arguments = arguments
			@options = options
		end
		
		attr :arguments
		
		# The command required to connect to the remote machine.
		def connection_command(server, *arguments)
			[*@command, *@arguments, *arguments, server.host]
		end
		
		def to_s
			"<#{self.class} #{@command} #{@options.inspect}>"
		end
	end
end
