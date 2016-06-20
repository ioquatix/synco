#!/usr/bin/env ruby

# You need to have the FSSM gem installed for this to work.
require 'fssm'

require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/rsync'
require 'lsync/event_timer'

MONITOR = ARGV.delete "-m"

# Check we've got two paths for sync.
unless ARGV.size == 2
	$stderr.puts "Usage: #{$0} [master] [copy]"
	exit(255)
end

script = LSync::Script.new do |script|
	script.method = LSync::Methods::RSync.new(:push, :arguments => ["--archive", "--delete"])
	
	script.master = :src
	
	server(:src) do |server|
		server.root = ARGV[0]
	end
	
	server(:dst) do |server|
		server.root = ARGV[1]
		
		#server.on(:prepare) do
		#	logger.warn "Aborting backup!"
		#	server.abort!
		#end
	end
	
	#server(:remote) do |server|
	#	server.host = "ayako.oriontransfer.org"
	#	server.shell = LSync::Shells::SSH.new(:user => "nobody")
	#	server.root = "/tmp/sync-test"
	#end
	
	#server(:remote2) do |server|
	#	server.host = "remote2.example.com"
	#	server.root = "/tmp/sync-test"
	#	
	#	server.on(:prepare) do |controller|
	#		controller.run! "mysqldump", "..."
	#	end
	#	
	#	server.on(:success) do |controller|
	#		controller.run! "uname", "-a"
	#	end
	#end
	
	backup('./')
end

# Initial sync:

context = LSync::Context.new(script)
context.run!

if MONITOR
	# Monitor directories for changes:
	monitor = FSSM::Monitor.new(:directories => true)

	# The event timer aggregates events into a single callback which will be called at most
	# once every k seconds (where k = 10 in this case).
	$event_timer = LSync::EventTimer.new(10) do
		$script.run!
	end

	$script.directories.each do |directory|
		full_path = $script[:src].full_path(directory)
		puts "Monitoring path: #{full_path}"
	
		monitor.path(full_path, "**/*") do
			update { $event_timer.trigger! }
			delete { $event_timer.trigger! }
			create { $event_timer.trigger! }
		end
	end

	begin
		monitor.run
	ensure
		# We should wait for the backup to complete nicely.
		$event_timer.join
	end
end
