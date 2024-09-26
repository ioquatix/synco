# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008-2024, by Samuel Williams.

require_relative "method"
require_relative "server"
require_relative "directory"
require_relative "controller"

require "socket"

require "process/group"

module Synco
	# The main backup/synchronisation mechanism is the backup script. It specifies all servers and directories, and these are then combined specifically to produce the desired data replication behaviour.
	class Script < Controller
		def initialize(method: nil, servers: {}, directories: [], master: :master)
			super()
			
			@method = method
			@servers = servers
			@directories = directories
			@master = master
		end
		
		def freeze
			current_server; master_server
			
			super
		end
		
		def running_on_master?
			current_server.same_host?(master_server)
		end
		
		def resolve_name(name)
			Socket.gethostbyname(name)[0]
		end
		
		def localhost?(name)
			return true if name == "localhost"

			host = resolve_name(Socket.gethostname)

			return name == host
		end
		
		# Given a name, find out which server config matches it.
		def find_named_server(name)
			if @servers.key? name
				@servers[name]
			else
				host = resolve_name(name)
				@servers.values.find{|server| server.host == host}
			end
		end

		alias :[] :find_named_server

		# The master server based on the name #master= specified
		def master_server
			@master_server ||= find_named_server(@master)
		end

		# Find the server that matches the current machine
		def find_current_server
			# There might be the case that the the local machine is both the master server and the backup server..
			# thus we check first if the master server is the local machine:
			if master_server and localhost?(master_server.host)
				@master_server
			else
				# Find a server config that specifies the local host
				@servers.values.find{|server| localhost?(server.host)}
			end || Server.new("localhost")
		end
		
		def current_server
			@current_server ||= find_current_server
		end

		# Register a server with the backup script.
		def server(*arguments, **options, &block)
			server = Server.build(*arguments, **options, &block)
			@servers[server.name] = server
		end

		# Backup a particular path (or paths).
		def directories(*paths, **options, &block)
			paths.each do |path|
				@directories << Directory.build(path, **options, &block)
			end
		end
		
		alias :copy :directories
		alias :backup :directories
		alias :sync :directories

		# The master server name (e.g. symbolic or host name)
		attr_accessor :master

		# A specific method which will perform the backup (e.g. an instance of Synco::Method)
		attr_accessor :method

		# All servers which are participating in the backup process.
		attr_accessor :servers

		# All directories which may be synchronised.
		attr_accessor :directories
	end
end
