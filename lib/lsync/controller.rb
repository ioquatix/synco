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

require 'process/group'

module LSync
	
	def self.log_task(task, logger)
		pipes = [task.output, task.error]

		while pipes.size > 0
			result = IO.select(pipes)

			result[0].each do |pipe|
				if pipe.closed? || pipe.eof?
					pipes.delete(pipe)
					next
				end

				if pipe == task.output
					logger.info pipe.readline.chomp
				elsif pipe == task.error
					logger.error pipe.readline.chomp
				end
			end
		end
	end
	
	def self.log_error(error, logger)
		logger.error "Error #{error.class.name}: #{error}"
		error.backtrace.each do |where|
			logger.error "\t#{where}"
		end
	end
	
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
			@method = method

			@connection = nil
		end

		def connect
			@connection ||= @server.connect
		end

		# The current server.
		attr :server
		
		# The backup method
		attr :method

		def run(*command, **options)
			root ||= options[:root] || @server.root
			
			if String === command
				command = [command]
			end
			
			lsync = options[:lsync] || "lsync"
			command = ["lsync", "--root", root, "spawn", "--", *command]
			
			result = self.exec(*command, **options)
			
			unless result.success?
				raise CommandFailure.new(command, result.exitstatus)
			end
		end

		# Run a command on the given server using this shell.
		def exec(*command, **options)
			unless @server.local?
				command = @server.shell.connection_command(@server) + ["--"] + command
			end

			@logger.info "#{command.inspect} (on #{@server})"
			
			process_status = nil
			
			Process::Group.wait do |group|
				group.run(*command, **options) do |status|
					@logger.info "... finished #{status}."
					process_status = status
				end
			end
			
			return process_status
		end

		def exec!(*command, **options)
			input, output = IO.pipe
			options[:out] = output
			
			result = exec(*command, **options)
			
			if result != 0
				raise CommandFailure.new(command, result.exitstatus)
			else
				output.close
				return input.read
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
