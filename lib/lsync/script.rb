
# A backup script coordinates "one" backup as a unit.

require 'lsync/action'
require 'lsync/method'
require 'lsync/server'
require 'lsync/directory'

module LSync
	
	# The server controller provides event handlers with a unified interface
	# for dealing with servers and associated actions.
	class ServerController
		def initialize(script, server, logger)
			@script = script
			@server = server
			@logger = logger
		end
		
		# The containing script.
		attr :script
		
		# The current server.
		attr :server
		
		# The output logger.
		attr :logger
		
		# Run a given shell script on the server.
		def run!(*function)
			action = Action.new(function)
			action.run_on_server(@server, @logger)
		end
	end
	
	# The directory controller provides event handlers with a unified interface
	# for dealing with a particular backup in a particular directory.
	class DirectoryController < ServerController
		def initialize(script, master, server, directory, logger)
			super(script, server, logger)
			
			@master = master
			@directory = directory
		end
		
		# The master server where data is being copied from.
		attr :master
		
		# The directory that the data is being copied within.
		attr :directory
	end
	
	# The main backup/synchronisation mechanism is the backup script. It specifies all
	# servers and directories, and these are then combined specifically to produce the
	# desired data replication behaviour.
	class Script
		include EventHandler
		
		def initialize(options = {}, &block)
			@logger = options[:logger] || Logger.new($stdout)
			@method = nil
			
			@servers = {}
			@directories = []

			@log = nil
			
			if block_given?
				instance_eval &block
			end
		end
		
		# Given a name, find out which server config matches it
		def find_named_server name
			if @servers.key? name
				return @servers[name]
			else
				hostname = Socket.gethostbyname(name)[0] rescue name
				return @servers.values.find { |s| s["host"] == hostname }
			end
		end
		
		alias :[] :find_named_server
		
		# Find the master server based on the name #master= specified
		def find_master_server
			find_named_server(@master)
		end
		
		# Find out the config section for the current server
		def find_current_server
			master = find_master_server
			server = nil
			
			# Find out if the master server is local...
			if master.is_local?
				server = master
			else
				# Find a server config that specifies the local host
				server = @servers.values.find { |s| s.is_local? }
			end
			
			return server
		end
		
		# Register a server with the backup script.
		def server(name, &block)
			case name
			when Symbol
				host = "localhost"
			else
				host = name.to_s
			end
			
			server = Server.new(host)
			
			yield server if block_given?
			
			@servers[name] = server
		end
		
		# Backup a particular path (or paths).
		def backup(*paths, &block)
			paths.each do |path|
				directory = Directory.new(path)
				
				yield directory if block_given?
				
				@directories << directory
			end
		end

		# The script logger which will be provided all events when the script is run.
		attr :logger, true
		
		# The master server name (e.g. symbolic or host name)
		attr :master, true
		
		# A specific method which will perform the backup (e.g. an isntance of LSync::Method)
		attr :method, true
		
		# All servers which are participating in the backup process.
		attr :servers
		
		# All directories which may be synchronised.
		attr :directories
		
		# Log data (an +IO+) specific to the current script.
		attr :log
		
		# Run the backup process for all servers and directories specified.
		def run!
			start_time = Time.now
			
			# We buffer the log data so that if there is an error it is available to the notification sub-system
			@log = StringIO.new
			local_logger = Logger.new(@log)
			local_logger.formatter = MinimalLogFormat.new
			logger = @logger.tee(local_logger)

			master = find_master_server
			current = find_current_server

			# At this point we must know the current server or we can't continue
			if current == nil
				raise ScriptError.new("Could not determine current server!", :script => self, :master => @master)
			end

			if master.is_local?
				logger.info "We are the master server..."
			else
				logger.info "We are not the master server..."
				logger.info "Master server is #{@master}..."
			end

			master_controller = ServerController.new(self, master, logger)

			self.try do
				method.try do
					master.try(master_controller) do
						logger.info "Running backups for server #{current}..."
						
						run_backups!(master, current, logger)
					end
				end
			end
			
			end_time = Time.now
			logger.info "Backup Completed (#{end_time - start_time}s)."
		end
		
		protected
		
		# This function runs the method for each directory and server combination specified.
		def run_backups!(master, current, logger)
			@servers.each do |name, server|
				# S is always a data destination, therefore s can't be @master
				next if server == master

				# Skip servers that shouldn't be processed
				unless @method.should_run?(master, current, server)
					logger.info "\t" + "Skipping".rjust(20) + " : #{s}"
					next
				end

				server_controller = ServerController.new(self, server, logger)

				server.try(server_controller) do
					@directories.each do |directory|
						directory_controller = DirectoryController.new(self, master, server, directory, logger)

						directory.try(directory_controller) do
							logger.info "\t" + ("Processing " + directory.to_s).rjust(20) + " : #{server}"
					
							method.run(master, server, directory)
						end
					end
				end
			end
		end
	end

end
