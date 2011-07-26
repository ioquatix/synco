
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
