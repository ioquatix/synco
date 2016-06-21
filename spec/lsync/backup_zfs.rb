
require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/zfs'

LSync.run_script do |script|
	script.method = LSync::Methods::ZFS.new(:push)
	
	script.master = :src
	
	server(:src) do |server|
		server.root = '/tank/test/src'
	end
	
	server(:dst) do |server|
		server.root = '/tank/test/dst'
	end
	
	copy("/")
end
