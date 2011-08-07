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
		end

		# The current server.
		attr :server

		# Run a given shell script on the server.
		def run(*function)
			action = Action.new(function)
			action.run_on_server(@server, @logger)
		end
		
		def respond_to?(name)
			@server.respond_to?(name) || super(name)
		end
		
		def method_missing(name, *args, &block)
			@server.call(name, *args, &block)
		end
	end
	
	class CopyController < BasicController
		def initialize(script, logger, master, target)
			super(script, logger)
			
			@master = ServerController.new(script, logger, master)
			@target = ServerController.new(script, logger, target)
		end
		
		# The master server controller (where the data is being copied from).
		attr :master
		
		# The target server controller (where the data is being copied to).
		attr :target
	end
	
	# The directory controller provides event handlers with a unified interface
	# for dealing with a particular backup in a particular directory.
	class DirectoryController < CopyController
		def initialize(script, logger, master, target, directory)
			super(script, logger, master, target)

			@directory = directory
		end

		# The directory that the data is being copied within.
		attr :directory
	end
end
