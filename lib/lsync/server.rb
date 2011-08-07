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

require 'lsync/event_handler'
require 'lsync/shells/ssh'

module LSync
	class Server
		include EventHandler
		
		def initialize(host, options = {})
			@options = options
 
			@host = host
			@root = "/"

			@platform = nil

			@shell = Shells::SSH.new

			@enabled = true

			@roles = Set.new
		end
		
		# The roles that dictate how the server fits into the overall infratstructure.
		attr :roles, true
		
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

			return Pathname.new(p).cleanpath.normalize_trailing_slash
		end

		# Give a general connection string (e.g +"host:/directory"+ or +"/directory"+ if local).
		def connection_string(directory)
			if local?
				return full_path(directory)
			else
				return @host + ":" + full_path(directory).to_cmd
			end
		end

		def role?(role)
			@roles.include?(role) || @roles.include?(:all) || role == :any
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
