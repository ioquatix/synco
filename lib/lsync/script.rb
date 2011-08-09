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
require 'lsync/server'
require 'lsync/directory'
require 'lsync/controller'

module LSync
	# The main backup/synchronisation mechanism is the backup script. It specifies all
	# servers and directories, and these are then combined specifically to produce the
	# desired data replication behaviour.
	class Script
		include EventHandler

		def initialize(options = {}, &block)
			if options[:logger]
				@logger = options[:logger]
			else
				@logger = Logger.new($stdout)
				@logger.formatter = LSync::MinimalLogFormat.new
			end
			
			@method = nil

			@servers = {}
			@directories = []
			@master = "localhost"

			@log = nil

			if block_given?
				instance_eval &block
			end
		end

		# Given a name, find out which server config matches it
		def find_named_server(name)
			if @servers.key? name
				return @servers[name]
			else
				hostname = Socket.gethostbyname(name)[0] rescue name
				return @servers.values.find { |s| s.host == hostname }
			end
			
			# No server was found for this name
			return nil
		end

		alias :[] :find_named_server

		# Find the master server based on the name #master= specified
		def find_master_server
			server = find_named_server(@master)
			
			# At this point we must know the current server or we can't continue
			if server == nil
				raise ScriptError.new("Could not determine master server!", :script => self, :name => @master)
			end
			
			return server
		end

		# Find the server that matches the current machine
		def find_current_server
			master = find_master_server
			server = nil

			# There might be the case that the the local machine is both the master server and the backup server..
			# thus we check first if the master server is the local machine:
			if master.local?
				server = master
			else
				# Find a server config that specifies the local host
				server = @servers.values.find { |s| s.local? }
			end

			# At this point we must know the current server or we can't continue
			if server == nil
				raise ScriptError.new("Could not determine current server!", :script => self)
			end

			return server
		end

		# Register a server with the backup script.
		def server(name)
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
		def copy(*paths)
			paths.each do |path|
				directory = Directory.new(path)

				yield directory if block_given?

				@directories << directory
			end
		end

		alias :backup :copy

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
		def run!(options = {})
			start_time = Time.now

			logger.info "===== Starting backup at #{start_time} ====="

			# We buffer the log data so that if there is an error it is available to the notification sub-system
			@log = StringIO.new
			local_logger = Logger.new(@log)
			local_logger.formatter = MinimalLogFormat.new
			logger = @logger.tee(local_logger)

			master = find_master_server
			current = find_current_server

			if master.local?
				logger.info "We are the master server..."
			else
				logger.info "We are not the master server..."
				logger.info "Master server is #{@master}..."
			end

			master_controller = ServerController.new(self, logger, master)

			self.try(master_controller) do
				method.try(master_controller) do
					logger.info "Running backups for server #{current}..."

					run_backups!(master, current, logger, options)
				end
			end

			end_time = Time.now
			logger.info "[Time]: (#{end_time - start_time}s)."
			logger.info "===== Finished backup at #{end_time} ====="
		end

		protected

		# This function runs the method for each directory and server combination specified.
		def run_backups!(master, current, logger, options = {})
			@servers.each do |name, server|
				# S is always a data destination, therefore s can't be @master
				next if server == master

				next unless server.role?(options[:role] || :any)

				server_controller = CopyController.new(self, logger, master, server, current)

				# Skip servers that shouldn't be processed
				unless @method.should_run?(server_controller)
					logger.info "===== Skipping ====="
					logger.info "[Master]: #{master}"
					logger.info "[Target]: #{server}"
					next
				end

				logger.info "===== Processing ====="
				logger.info "[Master]: #{master}"
				logger.info "[Target]: #{server}"
				
				server.try(server_controller) do
					@directories.each do |directory|
						directory_controller = DirectoryController.new(self, logger, master, server, current, directory)

						logger.info "[Directory]: #{directory}"
						directory.try(directory_controller) do
							method.run(directory_controller)
						end
					end
				end
			end
		end
	end

end
