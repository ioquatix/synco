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

module LSync
	module Methods
		
		class RSync < Method
			protected
			
			def connect_arguments (local_server, remote_server)
				# RSync -e option simply appends the hostname. There is no way to control this behaviour.
				command = remote_server.shell.connection_command(remote_server)

				if command.last != remote_server.host
					abort "RSync shell requires hostname at end of command! #{cmd.inspect}"
				else
					command.pop
				end

				return ['-e', command.to_cmd]
			end

			public
			
			def initialize(direction, options = {})
				super(options)

				@direction = direction
				@command = options[:command] || "rsync"

				@options = options
				@connection = nil
			end
			
			def run(controller)
				directory = controller.directory
				arguments = (@options[:arguments] || ["--archive"]) + (directory.options[:arguments] || [])

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = controller.master
					remote_server = controller.target

					destination = remote_server.connection_string(directory)
					source = local_server.full_path(directory)
				else
					local_server = controller.target
					remote_server = controller.master

					source = remote_server.connection_string(directory)
					destination = local_server.full_path(directory)
				end

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				controller.target.exec!(["mkdir", "-p", controller.target.full_path(directory.path)])

				controller.logger.info "In directory #{Dir.getwd}..."
				Dir.chdir(local_server.root) do
					if run_handler(controller, source, destination, arguments) == false
						raise BackupMethodError.new("Backup from #{source.dump} to #{destination.dump} failed.", :method => self)
					end
				end
			end
			
			def run_handler(controller, source, destination, arguments)
				run_command(controller, [@command] + arguments + [source, destination])
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
			
			def run_command(controller, command)
				return LSync.run_command("/", command, controller.logger) == 0
			end
		end
		
		class RSyncSnapshot < RSync
			def inprogress_path
				@options[:inprogress_path] || "backup.inprogress"
			end
			
			def run(controller)
				directory = controller.directory
				arguments = (@options[:arguments] || []) + (directory.options[:arguments] || [])
				
				link_dest = Pathname.new("../" * (directory.path.depth + 1)) + "latest" + directory.path
				arguments += ['--archive', '--link-dest', link_dest.to_s]

				destination_directory = File.join(inprogress_path, directory.path)

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = controller.master
					remote_server = controller.target

					destination = remote_server.connection_string(destination_directory)
					source = local_server.full_path(directory)
				else
					local_server = controller.target
					remote_server = controller.master

					destination = local_server.full_path(destination_directory)
					source = remote_server.connection_string(directory)
				end

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				controller.target.exec!(["mkdir", "-p", controller.target.full_path(destination_directory)])

				Dir.chdir(local_server.root) do
					if run_handler(controller, source, destination, arguments) == false
						raise BackupMethodError.new("Backup from #{source.dump} to #{destination.dump} failed.", :method => self)
					end
				end
			end
		end
		
	end
end