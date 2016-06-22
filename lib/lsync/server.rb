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

require_relative 'event_handler'
require_relative 'shells/ssh'

require 'shellwords'

module LSync
	class Server
		include EventHandler
		
		def initialize(host, root: '/', **options)
			@options = options
 
			@host = host
			@root = root

			@shell = Shells::SSH.new
		end
		
		attr_accessor :mountpoint
		
		# The host name (e.g. DNS entry) for the given server.
		attr_accessor :host
		
		# The root path on the server in which all other directories will be relative to.
		attr_accessor :root
		
		# The shell to use to connect to the server.
		attr_accessor :shell

		# Give the full path for a particular subdirectory.
		def full_path(directory = "./")
			p = File.expand_path(directory.to_s, @root)

			return Pathname.new(p).cleanpath.normalize_trailing_slash
		end

		# Give a general connection string (e.g +"host:/directory"+ or +"/directory"+ if local).
		def connection_string(directory, on: nil)
			if self.host == on.host
				return full_path.to_s
			else
				return @host + ":" + Shellwords.escape(full_path(directory))
			end
		end
		
		def connection_command
			@shell.connection_command(self)
		end

		# Checks if the host resolves to the local machine.
		def local?
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
	end
end
