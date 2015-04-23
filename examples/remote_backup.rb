#!/usr/bin/env ruby

require 'rubygems'

require 'lsync'
require 'lsync/shells/ssh'
require 'lsync/methods/rsync'

TEST_SCRIPT = <<EOF
#!/usr/bin/env ruby

puts "Hello World " + ARGV.inspect

EOF

$script = LSync::Script.new do |script|
	script.method = LSync::Methods::RSyncSnapshot.new(:push, :arguments => ["--archive", "--compress", "--stats"])
	
	server("localhost") do |server|
		server.roles << :primary
		server.root = Pathname.new(__FILE__).dirname + "Data-Master"
	end
	
	server("ayako.oriontransfer.org") do |server|
		server.roles << :backup
		server.root = "/tmp/"
		
		server.on(:success) do
			target.run [TEST_SCRIPT, "foo", "bar"], :script => true
			target.run ["./scripts/test.rb", "foo", "bar", "baz"], :remote => true
		end
	end
	
	backup('./')
end

# We only run servers with the given role:
$script.run!(:role => :backup)
