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

require 'rexec/task'

module LSync

	def self.log_task(task, logger)
		pipes = [task.output, task.error]

		while pipes.size > 0
			result = IO.select(pipes)

			result[0].each do |pipe|
				if pipe.closed? || pipe.eof?
					pipes.delete(pipe)
					next
				end

				if pipe == task.output
					logger.info pipe.readline.chomp
				elsif pipe == task.error
					logger.error pipe.readline.chomp
				end
			end
		end
	end

	# Run a specific command and output the results to the given logger.
	def self.run_command(root, command, logger)
		Dir.chdir(root) do
			logger.info "Running #{command.inspect} in #{Dir.getwd.inspect}"

			process_result = RExec::Task.open(command) do |task|
				log_task(task, logger)
			end

			return process_result
		end
	end

	def self.run_remote_command(root, connection_command, command, logger)
		logger.info "Running remote command #{command.inspect} in #{root}"
		
		process_result = RExec::Task.open(connection_command) do |connection|
			connection.puts(["cd", root].to_cmd)
			connection.puts((["exec"] + command).to_cmd)
			
			LSync::log_task(connection, logger)
		end
		
		return process_result
	end
end