#!/usr/bin/env ruby

require 'rubygems'

require 'lsync'
require 'lsync/methods/rsync'

LSync::run_script do |script|
	script.method = LSync::Methods::RSync.new(:push, :arguments => ["--archive", "--delete"])
	
	script.master = :src
	
	server(:src) do |server|
		server.root = Pathname.new("./Data-Master").realpath
	end
	
	server(:dst) do |server|
		server.root = Pathname.new("./Data-Master-Sync").expand_path
		
		server.on(:success) do
			target.run_script "./scripts/test.rb"
		end
	end
	
	backup('./')
end
