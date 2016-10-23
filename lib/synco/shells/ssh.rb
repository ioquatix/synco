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

module Synco
	module Shells
		# SSH shell provides access to a remote server using SSH.
		class SSH < Shell
			def default_command
				['ssh']
			end
			
			def initialize(*command, arguments: [], port: nil, key: nil, user: nil, batch_mode: nil, **options)
				if port
					arguments << '-p' << port
				end
				
				if key
					arguments << '-i' << key
				end
				
				if user
					arguments << '-l' << user
				end
				
				unless batch_mode.nil?
					arguments << '-o' << "BatchMode=#{batch_mode ? 'yes' : 'no'}"
				end
				
				super
			end
		end
	end
end
