# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'controller'
require_relative 'directory'
require_relative 'shells/ssh'

require 'shellwords'

module LSync
	class Server < Controller
		def initialize(name, root: '/', shell: nil, **options)
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

			puts "#{directory}, #{@root} -> #{path}"

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
