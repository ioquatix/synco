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

require 'pathname'
require 'fileutils'

$connection.run do |object|
	case(object[0])
	when :chdir
		# [:chdir, :path]
		Dir.chdir(object[1])
	when :script
		# [:script, :command, :data]
		
		command = object[1]
		script_name = File.basename(command[0])
		
		local_path = `mktemp -t #{script_name.gsub(/[^a-z]/i, '')}.XXXX`.chomp
		
		File.open(local_path, 'w') { |fp| fp.write(object[2]) }
		system('chmod', '+x', local_path)
		
		pid = fork do
			command[0] = local_path
			exec *command
		end
		
		# Clean up the script after execution:
		pid, result = Process.wait2(pid)
		# system('rm', '-f', local_path)
		
		exit!(result.exitstatus)
	when :exec
		# [:exec, :command]
		command = object[1]
		
		exec *command
	end
end
