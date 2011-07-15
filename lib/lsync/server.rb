
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
		
		attr :host, true
		attr :root, true
		attr :platform, true
		attr :shell, true

		def full_path(directory = "./")
			p = File.expand_path(directory.to_s, @root)

			return Pathname.new(p).cleanpath.normalize_trailing_slash.to_s
		end

		def connection_string(directory)
			if is_local?
				return full_path(directory)
			else
				return @host + ":" + full_path(directory).dump
			end
		end

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

		def to_s
			"#{@host}:#{full_path}"
		end

		def should_run?
			return @enabled
		end

		def connect
			unless @connection
				@connection, @pid = @shell.connect(self)
			end

			return @connection
		end
	end
end
