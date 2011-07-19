#!/usr/bin/env ruby

require 'rubygems'

require 'ruby-growl'

require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/rsync'

# Check we've got two paths for sync.
unless ARGV.size == 2
	$stderr.puts "Usage: #{$0} [master] [copy]"
	exit(255)
end

$growl = Growl.new "localhost", "LSync", ["Backup Status"]
$growl.register

$script = LSync::Script.new do |script|
	# Use rsync snapshot method
	script.method = LSync::Methods::RSyncSnapshot.new(:push, :arguments => ["-a", "--compress", "--stats"])
	
	script.master = :src
	
	server(:src) do |server|
		server.root = ARGV[0]
	end
	
	server(:dst) do |server|
		server.root = ARGV[1]
		
		server.on(:success) do |controller|
			controller.run! :prune, "--default-policy"
			controller.run! :rotate, script.method.inprogress_path
		end
	end
	
	# This event is fired before the backup starts
	#script.on(:prepare) do
	#	$growl.notify "Backup Status", "Starting Backup", "Starting at #{Time.now.to_s}"
	#end
	#
	## This event occurs if the backup is successful
	#script.on(:success) do
	#	$growl.notify "Backup Status", "Backup Successful", script.log.string
	#end
	#
	## This event occurs if any part of the backup fails and is not handled elsewhere.
	#script.on(:failure) do |failure|
	#	$growl.notify "Backup Status", "Backup Failure", failure.to_s
	#	
	#	raise failure
	#end
	
	backup('./')
end

$script.run!