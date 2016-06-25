# Copyright, 2016, Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../method'

module LSync
	module Methods
		class ZFS < Method
			def default_command
				['zfs', '-rnv']
			end
			
			def call(scope, arguments: [])
				from_server = scope.current_server
				master_server = scope.master_server
				target_server = scope.target_server
				directory = scope.directory
				
				send_command = [
					*@command,
					"send",
					master_server.full_path(directory)
				]
				
				receive_command = [
					*@command,
					"receive",
					target_server.full_path(directory)
				]
				
				input, output = IO.pipe
				
				Fiber.new do
					master_server.run(*send_command, out: output, from: from_server)
					output.close
				end.resume
				
				target_server.run(*receive_command, in: input, from: from_server)
				input.close
			end
		end
	end
end