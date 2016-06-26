#!/usr/bin/env ruby

require 'synco'
require 'synco/shells/ssh'
require 'synco/methods/rsync'

Synco::run_script do |script|
	self.method = Synco::Methods::RSyncSnapshot.new
	
	server(:source) do |server|
		self.root = '/Users/samuel/'
	end
	
	server(:destination) do |server|
		self.mountpoint = '/Volumes/BRUCE64/'
		self.root = server.mountpoint + 'samuel'
		
		on(:prepare) do
			run "synco", "mount", self.mountpoint
		end
		
		# Runs after all directories have been successfully backed up.
		on(:success) do
			run "synco", "rotate", chdir: self.root
			run "synco", "prune", chdir: self.root
		end
		
		on(:finish) do
			run "synco", "unmount", self.mountpoint
		end
	end
	
	backup('Desktop')
end
