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

require 'rexec'
require 'pathname'

module LSync
	CLIENT_CODE = (Pathname.new(__FILE__).dirname + "client.rb").read

	# There was an error establishing a connection with a server.
	class ConnectionError < StandardError
	end
	
	# A shell provides access to a server, typically to run an instance of `ruby`.
	class Shell
		def initialize(command, options = {})
			case command
			when Array
				@command = command
			else
				@command = [command]
			end
			
			@options = options
		end
		
		def ruby_command
			@options[:ruby] || ["ruby"]
		end
		
		# The command required to connect to the remote machine.
		def connection_command(server, arguments = [])
			@command + (@options[:arguments] || []) + arguments + [server.host]
		end
		
		def connect(server)
			options = {:passthrough => []}
			if server.local?
				return RExec::start_server(CLIENT_CODE, ruby_command, options)
			else
				return RExec::start_server(CLIENT_CODE, connection_command(server) + ruby_command, options)
			end
		end
	end
end
