
require 'lsync/shell'

module LSync
	module Shells
		# SSH shell provides access to a remote server using SSH.
		class SSH < Shell
			def initialize(options = {})
				super(options[:command] || "ssh", options)
			end
			
			# The connection options for ssh
			# [`:port`]        The remote port to use.
			# [`:key`]         A specific key file to use.
			# [`:keys`]        A specific array of key files to use.
			# [`:timeout`]     How long to wait until connection fails if no response is received.
			# [`:compression`] Enable compression.
			# [`:user`]        Connect as a specific user.
			def command_arguments
				args = []

				if @name == "ssh"
					@options.each do |k,v|
						case(k.to_sym)
						when :port
							args << ['-p', v.to_i]
						when :key
							args << ['-i', v.dump]
						when :keys
							v.each { |key_path| args << ['-i', key_path.dump] } 
						when :timeout
							args << ['-o', "ConnectTimeout #{v.to_i}".dump]
						when :compression
							args << ['-C'] if v
						when :user
							args << ['-l', v.to_s.dump]
						end
					end
				end

				return args
			end
			
			def connection_command(server, arguments = [])
				super(server, arguments + command_arguments)
			end
		end
	end
end
