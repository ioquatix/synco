#!/usr/bin/env ruby

require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/rsync'

LSync::run_script do |script|
	script.method = LSync::Methods::RSyncSnapshot.new(:push, "--archive", "--compress", "--stats")
	
	script.master = :src
	
	server(:src) do |server|
		server.root = '/Users/samuel/'
	end
	
	server(:dst) do |server|
		server.mountpoint = '/Volumes/BRUCE64/'
		server.root = server.mountpoint + 'samuel'
		
		server.on(:prepare) do
			target.exec! :lsync, :mount, server.mountpoint
		end
		
		# Runs after all directories have been successfully backed up.
		server.on(:success) do
			target.run :lsync, :rotate
			target.run :lsync, :prune
		end
		
		server.on(:done) do
			target.exec! :lsync, :unmount, server.mountpoint
		end
	end
	
	backup('Desktop')
end
