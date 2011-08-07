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
			
			def run(master_server, target_server, directory)
				arguments = (@options[:arguments] || ["--archive"]) + (directory.options[:arguments] || [])

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = master_server
					remote_server = target_server

					dst = remote_server.connection_string(directory)
					src = local_server.full_path(directory)
				else
					local_server = target_server
					remote_server = master_server

					src = remote_server.connection_string(directory)
					dst = local_server.full_path(directory)
				end

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				@connection = target_server.connect
				@connection.send_object([:mkdir_p, target_server.full_path(directory)])

				@logger.info "In directory #{Dir.getwd}..."
				Dir.chdir(local_server.root) do
					if run_handler(src, dst, arguments) == false
						raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
					end
				end
			end
			
			def run_handler(src, dst, arguments)
				run_command([@command] + arguments + [src, dst])
			end
			
			def should_run?(master_server, current_server, target_server)
				if @direction == :push
					return current_server == master_server
				elsif @direction == :pull
					return target_server.is_local?
				else
					return false
				end
			end
			
			def run_command(cmd)
				return LSync.run_command(cmd, @logger) == 0
			end
		end
		
		class RSyncSnapshot < RSync
			def inprogress_path
				@options[:inprogress_path] || "backup.inprogress"
			end
			
			def run(master_server, target_server, directory)
				arguments = (@options[:arguments] || []) + (directory.options[:arguments] || [])
				
				link_dest = Pathname.new("../" * (directory.path.depth + 1)) + "latest" + directory.path
				arguments += ['--archive', '--link-dest', link_dest.to_s]

				dst_directory = File.join(inprogress_path, directory.to_s)

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = master_server
					remote_server = target_server

					dst = remote_server.connection_string(dst_directory)
					src = local_server.full_path(directory)
				else
					local_server = target_server
					remote_server = master_server

					dst = local_server.full_path(dst_directory)
					src = remote_server.connection_string(directory)
				end

				arguments += connect_arguments(local_server, remote_server)

				# Create the destination backup directory
				@connection = target_server.connect
				@connection.send_object([:mkdir_p, target_server.full_path(dst_directory)])

				Dir.chdir(local_server.root) do
					if run_handler(src, dst, arguments) == false
						raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
					end
				end
			end
		end
		
	end
end