
require 'rexec'
require 'pathname'

module LSync
	CLIENT_CODE = (Pathname.new(__FILE__).dirname + "shell_client.rb").read
	
	# There was an error establishing a connection with a server.
	class ConnectionError < StandardError
	end
	
	# A shell provides access to a server, typically to run an instance of `ruby`.
	class Shell
		def initialize(command, options = {})
			case command
			when Array
				@command = command
			else
				@command = [command]
			end
			
			@options = options
		end
		
		# The command required to start an instance of Ruby.
		def ruby_command
			@options[:ruby] || ["ruby"]
		end
		
		# The command required to connect to the remote machine.
		def connection_command(server, arguments = [])
			@command + (@options[:arguments] || []) + arguments + [server.host]
		end
		
		# Establish a connection to the server using this shell configuration.
		def connect(server)
			begin
				connection, pid = open_connection(server)
				message = connection.receive_object
			ensure
				connection.dump_errors if connection
			end
			
			if message != :ready
				raise ConnectionError.new("Remote shell connection was not successful: #{message}")
			end
			
			return connection, pid
		end
		
		protected
		# Return a connection object representing a connection to the given server.
		def open_connection(server)
			command = ruby_command
			
			unless server.is_local?
				command = connection_command(server) + command
			end
			
			return RExec::start_server(CLIENT_CODE, command)
		end
	end
	
end
