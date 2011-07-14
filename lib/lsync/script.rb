
# A backup script coordinates "one" backup as a unit.

require 'lsync/action'
require 'lsync/method'
require 'lsync/server'
require 'lsync/directory'

module LSync
	
	class Script
		include EventHandler
		
		private
		# Given a name, find out which server config matches it
		def find_named_server name
			if @servers.key? name
				return @servers[name]
			else
				hostname = Socket.gethostbyname(name)[0] rescue name
				return @servers.values.find { |s| s["host"] == hostname }
			end
		end
		
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
		
		public
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
		
		def backup(*paths, &block)
			paths.each do |path|
				puts path.inspect
				directory = Directory.new(path)
				
				yield directory if block_given?
				
				@directories << directory
			end
		end

		attr :logger, true
		attr :master, true
		attr :method, true
		attr :servers
		attr :directories
		attr :log
		
		def run!
			# We buffer the log data so that if there is an error it is available to the notification sub-system
			@log = StringIO.new
			logger = @logger.tee(Logger.new(@log))

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

			# Run server pre-scripts.. if these fail then we abort the whole backup
			begin
				method.fire(:prepare)
				master.fire(:prepare)
			rescue AbortBackupException
				# This specific error causes the backup to be aborted and is not considered a real error.
				return
			end

			logger.info "Running backups for server #{current}..."

			@servers.each do |name, server|
				# S is always a data destination, therefore s can't be @master
				next if server == master

				# Skip servers that shouldn't be processed
				unless @method.should_run?(master, current, server)
					logger.info "\t" + "Skipping".rjust(20) + " : #{s}"
					next
				end

				# Run pre-scripts for a particular server
				begin
					server.fire(:prepare)
				rescue AbortBackupException
					next
				end

				@directories.each do |directory|
					logger.info "\t" + ("Processing " + directory.to_s).rjust(20) + " : #{server}"
					
					method.run(master, server, directory)
				end

				# Run post-scripts for a particular server
				server.fire(:success)
			end

			master.fire(:success)
			method.fire(:success)
		end
	end

end
