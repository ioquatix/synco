
require 'pathname'
require 'lsync/run'
require 'lsync/error'

module LSync

	class AbortBackupException < StandardError
	end
	
	# A runnable action, such as a shell command or action script.
	#
	# If the first argument is a symbol, then this will map to one of the standard
	# actions in the `lsync/actions` subdirectory. These actions are sometimes implemented
	# on a per-platform basis.
	class Action
		def initialize(function)
			@function = function
			
			case @function[0]
			when Symbol
				@script_name = @function[0].to_s
				@arguments = @function[1,@function.size]
			else
				@script_name = nil
			end
		end

		# Return a string representation of the action for logging.
		def to_s
			@function.to_cmd
		end

		# Run the action on the given server, typically in the root directory specified.
		def run_on_server(server, logger)
			# logger.info "Running #{@function.to_cmd} on #{server}"

			if server.is_local?
				run_locally(server, logger)
			else
				run_remotely(server, logger)
			end
		end

		private
		# Run the script locally by invoking it directly.
		def run_locally(server, logger)
			command = nil

			if @script_name
				uname = `uname`.chomp.downcase

				local_path = Action.script_path(uname, @script_name)
				command = [local_path] + @arguments
			else
				command = @function
			end

			result = nil
			Dir.chdir(server.root) do
				result = LSync.run_command(command, logger)
			end

			if result != 0
				raise ShellScriptError.new(command, result)
			end
		end

		# Run the script remotely by sending the data across the network and executing it.
		def run_remotely(server, logger)
			conn = server.connect
			conn.send_object([:set_working_dir, server.root])

			if @script_name
				uname = `uname`.chomp.downcase

				local_path = Action.script_path(uname, @script_name)

				logger.info("Sending run_script #{@script_name}...")
				conn.send_object([:run_script, @script_name, Pathname.new(local_path).read, @arguments])
			else
				logger.info("Sending run_command #{@function}...")
				conn.send_object([:run_command, @function])
			end

			conn.run do |message|
				break if message == :done

				logger.send(*message)
			end
		end

		# Figure out the path of the script, which may depend on the given platform.
		def self.script_path(platform, name)
			exact_script_path(platform, name) || exact_script_path("generic", name)
		end

		# Return the exact path of a builtin action script.
		def self.exact_script_path(platform, name)
			path = (Pathname.new(__FILE__).dirname + "actions" + platform + name).expand_path
			path.exist? ? path : nil
		end
	end

end