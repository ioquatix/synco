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

require_relative '../method'

module Synco
	module Methods
		class SCP < Method
			def default_command
				['scp', '-prB']
			end
			
			def call(scope)
				server = scope.current_server
				directory = scope.directory
				
				server.run(
					*@command,
					*arguments,
					# If the destination directory already exists, scp will create the source directory inside the destinatio directory. This behaviour means that running scp multiple times gives different results, i.e. the first time it will copy source/* to destination/*, but the second time you will end up with destination/source/*. Putting a dot after the first path alleviates this issue for some reason.
					scope.master_server.connection_string(directory, on: server) + '.',
					scope.target_server.connection_string(directory, on: server)
				)
			end
		end
	end
end