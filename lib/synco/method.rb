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

require 'fileutils'
require 'pathname'
require_relative 'controller'

module Synco
	SNAPSHOT_NAME = 'latest.snapshot'
	LATEST_NAME = 'latest'
	BACKUP_NAME = '%Y.%m.%d-%H.%M.%S'
	BACKUP_TIMEZONE = 'UTC'
	
	# A backup method provides the interface to copy data from one system to another.
	class Method < Controller
		def initialize(*command, arguments: [], **options)
			super()
			
			@command = command.empty? ? default_command : command
			@arguments = arguments
			@options = options
		end
		
		attr :options
		attr :arguments
		
		def call(scope, arguments: [])
			server = scope.current_server
			directory = scope.directory
			
			server.run(
				*@command,
				*arguments,
				scope.master_server.connection_string(directory, on: server),
				scope.target_server.connection_string(directory, on: server)
			)
		end
	end
end
