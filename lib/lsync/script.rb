
# A backup script coordinates "one" backup as a unit.

require 'lsync/action'
require 'lsync/method'
require 'lsync/server'
require 'lsync/directory'

module LSync

	class Script
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

		# Find out the config section for the current server
		def find_current_server
			server = nil

			# Find out if the master server is local...
			if @master.is_local?
				server = @master
			else
				# Find a server config that specifies the local host
				server = @servers.values.find { |s| s.is_local? }
			end

			return server
		end

		def script_logger
			if @config["log-file"]
				return Logger.new(@config["log-file"], 'weekly')
			end
		end

		public
		def initialize(config, logger = nil)
			@config = config

			@logger = logger || Logger.new(STDOUT)

			@servers = config.keys_matching(/^server\./) { |c,n| Server.new(c) }
			@directories = config.keys_matching(/^directory\./) { |c,n| Directory.new(c) }

			@master = find_named_server(config["master"])

			if @master == nil
				raise ConfigurationError.new("Could not determine master server!", :script => self)
			end

			@method = Method.new(config["method"])
			@log_buffer = nil
		end

		attr :logger, true
		attr :master
		attr :method
		attr :servers
		attr :directories
		attr :log_buffer

		def run_backup
			# We buffer the log data so that if there is an error it is available to the notification sub-system
			@log_buffer = StringIO.new
			logger = @logger.tee(script_logger, Logger.new(@log_buffer))

			current = find_current_server

			# At this point we must know the current server or we can't continue
			if current == nil
				raise ScriptError.new("Could not determine current server!", :script => self, :master => @master)
			end

			if @master.is_local?
				logger.info "We are the master server..."
			else
				logger.info "We are not the master server..."
				logger.info "Master server is #{@master}..."
			end

			# Run server pre-scripts.. if these fail then we abort the whole backup
			begin
				@method.run_actions(:before, logger)
				@master.run_actions(:before, logger)
			rescue AbortBackupException
				return
			end

			logger.info "Running backups for server #{current}..."

			@servers.each do |name, s|
				# S is always a data destination, therefore s can't be @master
				next if s == @master

				# Skip servers that shouldn't be processed
				unless @method.should_run?(@master, current, s)
					logger.info "\t" + "Skipping".rjust(20) + " : #{s}"
					next
				end

				# Run pre-scripts for a particular server
				begin
					s.run_actions(:before, logger)
				rescue AbortBackupException
					next
				end

				@directories.each do |name, d|
					logger.info "\t" + ("Processing " + d.to_s).rjust(20) + " : #{s}"

					@method.logger = logger
					@method.run(@master, s, d)
				end

				# Run post-scripts for a particular server
				s.run_actions(:after, logger)
			end

			@method.run_actions(:after, logger)
			@master.run_actions(:after, logger)
		end

		def self.load_from_file(path)
			new(YAML::load(File.read(path)))
		end
	end

end
