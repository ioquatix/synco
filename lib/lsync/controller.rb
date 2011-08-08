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

module LSync
	class BasicController
		def initialize(script, logger)
			@script = script
			@logger = logger
		end

		# The containing script.
		attr :script

		# The output logger.
		attr :logger
	end
	
	# The server controller provides event handlers with a unified interface
	# for dealing with servers and associated actions.
	class ServerController < BasicController
		def initialize(script, logger, server)
			super(script, logger)

			@server = server

			@connection = nil
			@platform = nil
		end

		# The current server.
		attr :server

		def run(command, options = {})
			task = nil
			
			root ||= options[:root] || @server.root
			
			if String === command
				command = [command]
			end
			
			begin
				connection, task = @server.shell.connect(@server)
				connection.send_object([:chdir, root])
				
				if options[:script]
					data = command[0]
					
					command = command.dup
					
					# Descriptive name can be provided by options[:script].
					case options[:script]
					when String
						command[0] = options[:script]
					else
						command[0] = "script"
					end
					
					@logger.info "Running script #{command.inspect} on #{@server}"
					
					connection.send_object([:script, command, data])
				elsif options[:remote]
					@logger.info "Running script #{command.inspect} on #{@server}"
					
					data = File.read(command[0])
					connection.send_object([:script, command, data])
				else
					@logger.info "Running command #{command.inspect} on #{@server}"
					connection.send_object([:exec, command])
				end
				
				if block_given?
					yield task
				else
					LSync::log_task(task, @logger)
				end
			ensure
				if task
					task.stop
					task.wait
				end
			end
		end

		# Run a command on the given server using this shell.
		def exec(command, options = {}, &block)
			unless @server.local?
				command = @server.shell.connection_command(@server) + ["--"] + command
			end

			@logger.debug "Executing #{command.inspect} on #{@server}"
			RExec::Task.open(command, options, &block)
		end

		def exec!(command, options = {})
			exec(command, options) do |task|
				task.input.close

				result = task.wait

				unless result.exitstatus == 0
					raise ShellScriptError.new("Command #{command.inspect} failed: #{result.exitstatus}", result.exitstatus)
				end

				return task.output.read
			end
		end

		def ==(other)
			@server == other.server
		end
		
		def respond_to?(name)
			@server.respond_to?(name) || super(name)
		end
		
		def method_missing(name, *args, &block)
			@server.send(name, *args, &block)
		end
	end
	
	class CopyController < BasicController
		def initialize(script, logger, master, target, current)
			super(script, logger)
			
			@master = ServerController.new(script, logger, master)
			@target = ServerController.new(script, logger, target)
			@current = ServerController.new(script, logger, current)
		end
		
		# The master server controller (where the data is being copied from).
		attr :master
		
		# The target server controller (where the data is being copied to).
		attr :target
		
		# The current server controller (the controller for the local machine).
		attr :current
	end
	
	# The directory controller provides event handlers with a unified interface
	# for dealing with a particular backup in a particular directory.
	class DirectoryController < CopyController
		def initialize(script, logger, master, target, current, directory)
			super(script, logger, master, target, current)

			@directory = directory
		end

		# The directory that the data is being copied within.
		attr :directory
	end
end
