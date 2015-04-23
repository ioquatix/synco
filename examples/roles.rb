#!/usr/bin/env ruby

require 'rubygems'

require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/rsync'

$script = LSync::Script.new do |script|
	script.method = LSync::Methods::RSyncSnapshot.new(:pull, :arguments => ["--archive", "--compress", "--stats"])
	script.actions_path << Pathname.new(__FILE__).dirname + "actions"
	script.master = "server.example.com"
	
	# These servers are all source servers, but only one of them will be selected to be the master.
	server("server-a.example.com") do |server|
		server.role = :primary
	end
	
	server("server-b.example.com") do |server|
		server.role = :primary
	end
	
	server("server-b.example.com") do |server|
		server.role = :primary
	end
	
	server("backup.example.com") do |server|
		server.role = :backup
		server.root = "/mnt/backups/server.example.com"
		
		server.on(:success) do
			target.run :rotate, script.method.inprogress_path
			target.run :prune, "--default-policy"
		end
	end
	
	backup('./')
end

# We only run servers with the given role:
$script.run!(:role => :backup)
