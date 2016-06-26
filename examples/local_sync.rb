#!/usr/bin/env ruby

require 'rubygems'

require 'synco'
require 'synco/methods/rsync'

Synco::run_script do |script|
	script.method = Synco::Methods::RSync.new(:push, :arguments => ["--archive", "--delete"])
	
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
