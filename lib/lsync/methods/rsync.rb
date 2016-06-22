# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
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

require 'lsync/method'
require 'shellwords'

module LSync
	module Methods
		class RSync
			def initialize(command: 'scp')
				@command = command
			end
			
			def run(controller)
				directory = controller.directory
				
				controller.master.run(
					@command,
					controller.master.connection_string(directory)
					controller.target.connection_string(directory)
				)
			end
		end
		
		
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
			def initialize(direction, *arguments, **options)
				super(options)

				@direction = direction
				@rsync = options[:rsync] || "rsync"
			end
			
		protected
			
			def connect_arguments (local_server, remote_server)
				# This gives the command required to connect to the remote server, e.g. `ssh example.com`
				command = remote_server.connection_command

				# RSync -e option simply appends the hostname. There is no way to control this behaviour.
				if command.last != remote_server.host
					abort "RSync shell requires hostname at end of command! #{cmd.inspect}"
				else
					command.pop
				end

				return ['-e', Shellwords.join(command)]
			end

			def configuration(controller, source_directory, destination_directory)
				local_server = nil
				remote_server = nil
				source = nil
				destination = nil

				if @direction == :push
					local_server = controller.master
					remote_server = controller.target

					destination = remote_server.connection_string(destination_directory)
					source = local_server.full_path(source_directory)
				else
					local_server = controller.target
					remote_server = controller.master

					source = remote_server.connection_string(source_directory)
					destination = local_server.full_path(destination_directory)
				end
				
				return local_server, remote_server, source, destination
			end
			
			def run_handler(controller, local_server, source, destination, arguments)
				command = [@rsync] + arguments + [source, destination]

				local_server.exec(*command) do |task|
					LSync::log_task(task, controller.logger)

					result = task.wait

					# Exit status 24 means that some files were deleted between indexing the data and copying it.
					unless result.exitstatus == 0 || result.exitstatus == 24
						raise BackupMethodError.new("Backup from #{source} to #{destination} failed.", :method => self)
					end
				end
			end
			
		public
			
			def run(controller)
				directory = controller.directory
				arguments = (@options[:arguments] || ["--archive"]) + (directory.options[:arguments] || [])

				local_server, remote_server, source, destination = configuration(controller, controller.directory, controller.directory)

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				controller.target.exec!("mkdir", "-p", controller.target.full_path(directory.path))

				run_handler(controller, local_server, source, destination, arguments)
			end
			
			def should_run?(controller)
				if @direction == :push
					return controller.current == controller.master
				elsif @direction == :pull
					return controller.target.local?
				else
					return false
				end
			end
		end
		
		class RSyncSnapshot < RSync
			def snapshot_name
				@options[:snapshot_name] || SNAPSHOT_NAME
			end
			
			def run(controller)
				directory = controller.directory
				arguments = (@options[:arguments] || []) + (directory.options[:arguments] || [])
				
				link_dest = Pathname.new("../" * (directory.path.depth + 1)) + "latest" + directory.path
				arguments += ['--archive', '--link-dest', link_dest.to_s]

				destination_directory = File.join(snapshot_name, directory.path)

				local_server, remote_server, source, destination = configuration(controller, controller.directory, destination_directory)

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				controller.target.exec!("mkdir", "-p", controller.target.full_path(destination_directory))

				run_handler(controller, local_server, source, destination, arguments)
			end
		end
		
	end
end