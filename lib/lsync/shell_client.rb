
require 'logger'
require 'fileutils'

require "open3"

LSYNC_TMP_DIRECTORY = "/tmp/lsync-#{Process.pid}"
FileUtils.mkdir_p(LSYNC_TMP_DIRECTORY)
FileUtils.chmod 0700, LSYNC_TMP_DIRECTORY
$logger = Logger.new "/tmp/remote-client.log"

$logger.info "Starting remote shell @ #{Time.now.to_s}"

def script_path(named)
	File.join(LSYNC_TMP_DIRECTORY, "#{named}")
end

module RemoteMethods
	# Run a command in the local environment.
	def self.run_command(cmd)
		$logger.info("Running #{cmd.inspect}...")
		$connection.send_object([:info, "Running #{cmd.inspect}..."])

		cin, cout, cerr = Open3.popen3(*cmd)
		cin.close

		pipes = [cout, cerr]

		while pipes.size > 0
			ready = IO.select(pipes)

			ready[0].each do |pipe|
				# Delete the pipe when it has become closed
				if pipe.closed? || pipe.eof?
					pipes.delete(pipe)
					next
				end

				line = pipe.readline.chomp
				mode = (pipe == cout ? :info : :error)

				$logger.send(mode, line)
				$connection.send_object([mode, line])
			end
		end

		$logger.info "Done running command."
		$connection.send_object(:done)
	end

	# Run a script (given the code) in the local environment.
	def self.run_script(name, code, arguments)
		path = script_path(name)

		File.open(path, "w") do |f|
			f.write(code)
		end

		FileUtils.chmod 0755, path

		run_command([path] + arguments)
	end

	# Recursively make a directory (typically the server.root + directory)
	def self.mkdir_p(path)
		FileUtils.mkdir_p(path)
	end

	# Set the working directory (typically the server.root)
	def self.set_working_dir(path)
		Dir.chdir(path)
	end
end

begin
	$connection.send_object(:ready)

	$connection.run do |message|
		method = message.shift
		$logger.info("Calling #{method}...")
		result = RemoteMethods.send(method, *message)
	end
rescue
	$logger.error("Exception caught: #{$!}")
	exit(1)
ensure
	FileUtils.rm_rf(LSYNC_TMP_DIRECTORY)
end
