
require 'pathname'
require 'lsync/run'
require 'lsync/error'

module LSync

	class AbortBackupException < StandardError
	end
	
	# A runnable action, such as a shell command or action script.
	#
	# If the function starts with `%`, e.g. `%prune` this will map to one of the standard
	# actions in the `lsync/actions` sub directory. These actions are generally implemented
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

		def to_s
			@function
		end

		def run_on_server(server, logger)
			# logger.info "Running #{@function.to_cmd} on #{server}"

			if server.is_local?
				run_locally(server, logger)
			else
				run_remotely(server, logger)
			end
		end

		private
		def run_locally(server, logger)
			command = nil

			if @script_name
				uname = `uname`.chomp.downcase

				local_path = Action.script_path(uname, @script_name)
				command = [local_path] + @arguments
			else
				command = @function
			end

			ret = nil
			Dir.chdir(server.root) do
				ret = LSync.run_command(command, logger)
			end

			case(ret)
			when 0
				return
			when 1
				raise AbortBackupException.new
			else
				raise BackupActionError.new
			end
		end

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

		def self.script_path(platform, name)
			exact_script_path(platform, name) || exact_script_path("generic", name)
		end

		private
		def self.exact_script_path(platform, name)
			path = (Pathname.new(__FILE__).dirname + "actions" + platform + name).expand_path
			path.exist? ? path : nil
		end
	end

end