
require 'rexec/task'

module LSync

	def self.run_command(command, logger)
		logger.info "Running: #{command.to_cmd} in #{Dir.getwd.dump}"

		process_result = RExec::Task.open(command) do |task|
			task.input.close
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

		return process_result
	end

end