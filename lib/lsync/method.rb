
require 'fileutils'
require 'pathname'
require 'lsync/run'

module LSync

	class Method
		@@methods = {}

		def self.register(name, handler)
			@@methods[name] = handler
		end

		def self.lookup(name)
			@@methods[name]
		end

		def initialize(config, logger = nil)
			@logger = logger || Logger.new(STDOUT)

			@name, @options = config.split(/\s+/, 2)

			@method = Method.lookup(@name)

			if @method == nil
				raise BackupError.new("Could not find method #{@name}!")
			end
		end

		attr :logger, true

		def run(master_server, target_server, directory)
			@method.run(master_server, target_server, directory, @options, @logger)
		end

		def should_run?(master_server, current_server, target_server)
			@method.should_run?(master_server, current_server, target_server)
		end

		def run_actions(actions, logger)
		end
	end

	module Methods
		module DirectionalMethodHelper
			protected
			def connect_options_for_server (local_server, remote_server)
				# RSync -e option simply appends the hostname. There is no way to control this behaviour.
				cmd = remote_server.shell.full_command(remote_server)

				if cmd.match(/ #{remote_server.host}$/)
					cmd.gsub!(/ #{remote_server.host}$/, "")
				else
					abort "RSync shell requires hostname at end of command! #{cmd.dump}"
				end

				['-e', cmd.dump].join(" ")
			end

			public
			def initialize(direction)
				@direction = direction
			end

			def run(master_server, target_server, directory, options, logger)
				options ||= ""

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = master_server
					remote_server = target_server

					dst = remote_server.connection_string(directory)
					src = local_server.full_path(directory)
				else
					local_server = target_server
					remote_server = master_server

					src = remote_server.connection_string(directory)
					dst = local_server.full_path(directory)
				end

				options += " " + connect_options_for_server(local_server, remote_server)

				# Create the destination backup directory
				@connection = target_server.connect
				@connection.send_object([:mkdir_p, target_server.full_path(directory)])

				@logger = logger

				@logger.info "In directory #{Dir.getwd}"
				Dir.chdir(local_server.root_path) do
					if run_handler(src, dst, options) == false
						raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
					end
				end
			end

			def should_run?(master_server, current_server, target_server)
				if @direction == :push
					return current_server == master_server
				elsif @direction == :pull
					return target_server.is_local?
				else
					return false
				end
			end

			def run_command(cmd)
				return LSync.run_command(cmd, @logger) == 0
			end
		end

		class RSync
			include DirectionalMethodHelper

			def run_handler(src, dst, options)
				run_command("rsync #{options} #{src.dump} #{dst.dump}")
			end
		end

		Method.register("rsync-pull", RSync.new(:pull))
		Method.register("rsync-push", RSync.new(:push))

		class RSyncSnapshot < RSync
			def run(master_server, target_server, directory, options, logger)
				options ||= ""
				link_dest = Pathname.new("../" * (directory.path.depth + 1)) + "latest" + directory.path
				options += " --archive --link-dest #{link_dest.to_s.dump}"

				inprogress_path = ".inprogress"
				dst_directory = File.join(inprogress_path, directory.to_s)

				local_server = nil
				remote_server = nil

				if @direction == :push
					local_server = master_server
					remote_server = target_server

					dst = remote_server.connection_string(dst_directory)
					src = local_server.full_path(directory)
				else
					local_server = target_server
					remote_server = master_server

					dst = local_server.full_path(dst_directory)
					src = remote_server.connection_string(directory)
				end

				options += " " + connect_options_for_server(local_server, remote_server)

				# Create the destination backup directory
				@connection = target_server.connect
				@connection.send_object([:mkdir_p, target_server.full_path(dst_directory)])

				@logger = logger

				Dir.chdir(local_server.root_path) do
					if run_handler(src, dst, options) == false
						raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
					end
				end
			end
		end

		Method.register("rsync-snapshot-pull", RSyncSnapshot.new(:pull))
		Method.register("rsync-snapshot-push", RSyncSnapshot.new(:push))

		class LinkBackup
			include DirectionalMethodHelper

			def self.lb_bin
				return File.join(File.dirname(__FILE__), "lb.py")
			end

			def run_handler(src, dst, options)
				# Verbose mode for debugging..
				# options += " --verbose"
				run_command("python #{LinkBackup.lb_bin.dump} #{options} #{src.dump} #{dst.dump}")
			end
		end

		Method.register("lb-pull", LinkBackup.new(:pull))
		Method.register("lb-push", LinkBackup.new(:push))

	end

end
