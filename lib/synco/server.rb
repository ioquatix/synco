# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

require_relative "controller"
require_relative "directory"
require_relative "shells/ssh"

require "shellwords"

module Synco
	class Server < Controller
		def initialize(name, root: "/", shell: nil, **options)
			super()
			
			@name = name
			
			case @name
			when Symbol
				@host = "localhost"
			else
				@host = name.to_s
			end
			
			@root = root
			@shell = shell || Shells::SSH.new
			
			@options = options
		end
		
		# The name of the server in the configuration (might be the same as the host).
		attr :name
		
		# The host name (e.g. DNS entry) for the given server.
		attr_accessor :host
		
		# The root path on the server in which all other directories will be relative to.
		attr_accessor :root
		
		# The shell to use to connect to the server.
		attr_accessor :shell

		attr_accessor :mountpoint

		# Give the full path for a particular subdirectory.
		def full_path(directory = "")
			path = File.expand_path(directory.to_s, @root)
			
			Directory.normalize(path)
		end

		# Give a general connection string (e.g +"host:/directory"+ or +"/directory"+ if local).
		def connection_string(directory, on: nil)
			if self.host == on.host
				return full_path(directory).to_s
			else
				return @host + ":" + Shellwords.escape(full_path(directory))
			end
		end
		
		def connection_command
			@shell.connection_command(self)
		end

		def same_host?(other)
			@host == other.host
		end

		# String representation of the server for logging.
		def to_s
			"#{@host}:#{full_path}"
		end
	end
end
