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

require_relative '../shell'

module LSync
	module Shells
		# SSH shell provides access to a remote server using SSH.
		class SSH < Shell
			def initialize(command: 'ssh', **options)
				super(command, options)
			end
			
			# The connection options for ssh
			# [`:port`]        The remote port to use.
			# [`:key`]         A specific key file to use.
			# [`:keys`]        A specific array of key files to use.
			# [`:timeout`]     How long to wait until connection fails if no response is received.
			# [`:compression`] Enable compression.
			# [`:user`]        Connect as a specific user.
			def command_arguments
				@options.collect do |k,v|
					case(k.to_sym)
					when :port
						['-p', v.to_s]
					when :key
						['-i', v]
					when :keys
						v.collect { |key_path| ['-i', key_path] } 
					when :timeout
						['-o', "ConnectTimeout #{v.to_i}".to_cmd]
					when :compression
						['-C'] if v
					when :user
						['-l', v.to_s]
					end
				end.flatten.compact
			end
			
			def connection_command(server, *arguments)
				super(server, *command_arguments+arguments)
			end
		end
	end
end
