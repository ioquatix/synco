# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../method'
require 'shellwords'

module LSync
	module Methods
		# RSync Exit Codes as of 2011:
		# 0      Success
		# 1      Syntax or usage error
		# 2      Protocol incompatibility
		# 3      Errors selecting input/output files, dirs
		# 4      Requested  action not supported: an attempt was made to manipulate 64-bit files on a platform 
		#        that cannot support them; or an option was specified that is supported by the client and not by the server.
		# 5      Error starting client-server protocol
		# 6      Daemon unable to append to log-file
		# 10     Error in socket I/O
		# 11     Error in file I/O
		# 12     Error in rsync protocol data stream
		# 13     Errors with program diagnostics
		# 14     Error in IPC code
		# 20     Received SIGUSR1 or SIGINT
		# 21     Some error returned by waitpid()
		# 22     Error allocating core memory buffers
		# 23     Partial transfer due to error
		# 24     Partial transfer due to vanished source files
		# 25     The --max-delete limit stopped deletions
		# 30     Timeout in data send/receive
		# 35     Timeout waiting for daemon connection
		
		class RSync < Method
			def default_command
				['rsync', '--archive', '--stats']
			end
			
			def connect_arguments(master_server, target_server)
				return [] if master_server.same_host?(target_server)
				
				# This gives the command required to connect to the remote server, e.g. `ssh example.com`
				command = target_server.connection_command

				# RSync -e option simply appends the hostname. There is no way to control this behaviour.
				if command.last != target_server.host
					raise ArgumentError.new("RSync shell requires hostname at end of command! #{command.inspect}")
				else
					command.pop
				end

				return ['-e', Shellwords.join(command)]
			end
			
			def call(scope)
				master_server = scope.master_server
				target_server = scope.target_server
				directory = scope.directory
				
				master_server.run(
					*@command,
					*@arguments,
					*connect_arguments(master_server, target_server),
					master_server.connection_string(directory, on: master_server),
					target_server.connection_string(directory, on: master_server)
				)
			rescue CommandFailure => failure
				raise unless failure.status.to_i == 24
			end
		end
		
		class RSyncSnapshot < RSync
			def snapshot_name
				@options[:snapshot_name] || SNAPSHOT_NAME
			end
			
			def latest_name
				@options[:latest_name] || LATEST_NAME
			end
			
			def call(scope)
				master_server = scope.master_server
				target_server = scope.target_server
				
				directory = scope.directory
				latest_path = File.join("../" * directory.depth, latest_name, directory.path)
				
				link_arguments = ['--link-dest', latest_path]
				incremental_path = File.join(snapshot_name, directory.path)
				
				# Create the destination backup directory
				target_server.run('mkdir', '-p', target_server.full_path(incremental_path))
				
				master_server.run(
					*@command,
					*@arguments,
					*connect_arguments(master_server, target_server),
					master_server.connection_string(directory, on: master_server),
					target_server.connection_string(incremental_path, on: master_server)
				)
			rescue CommandFailure => failure
				raise unless failure.status.to_i == 24
			end
		end
	end
end