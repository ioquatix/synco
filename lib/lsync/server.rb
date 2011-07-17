
require 'lsync/event_handler'
require 'lsync/shells/ssh'

module LSync
	class Server
		include EventHandler
		
		def initialize(host)
			@host = host
			@root = "/"
			
			@platform = "generic"
			
			@shell = Shells::SSH.new
			
			@enabled = true
			@connection = nil
			@pid = nil
		end
		
		# The host name (e.g. DNS entry) for the given server
		attr :host, true
		
		# The root path on the server in which all other directories will be relative to.
		attr :root, true
		
		# The platform of the server, e.g. linux, used for executing actions.
		attr :platform, true
		
		# The shell to use to connect to the server.
		attr :shell, true

		# Give the full path for a particular subdirectory.
		def full_path(directory = "./")
			p = File.expand_path(directory.to_s, @root)

			return Pathname.new(p).cleanpath.normalize_trailing_slash.to_s
		end

		# Give a general connection string (e.g +"host:/directory"+ or +"/directory"+ if local).
		def connection_string(directory)
			if is_local?
				return full_path(directory)
			else
				return @host + ":" + full_path(directory).dump
			end
		end

		# Checks if the host resolves to the local machine.
		def is_local?
			return true if @host == "localhost"

			hostname = Socket.gethostname

			begin
				hostname = Socket.gethostbyname(hostname)[0]
			rescue SocketError
				puts $!
			end

			return @host == hostname
		end

		# String representation of the server for logging.
		def to_s
			"#{@host}:#{full_path}"
		end

		# Connect to the server using the given #shell and #connection_string.
		def connect
			unless @connection
				@connection, @pid = @shell.connect(self)
			end

			return @connection
		end
	end
end
