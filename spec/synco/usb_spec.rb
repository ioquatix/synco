#!/usr/bin/env rspec

# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'synco/disk'
require 'synco/methods/rsync'
require_relative 'backup_script'

describe Synco::Methods::RSyncSnapshot, if: Synco::Disk.available?('TEST') do
	include_context "backup script"
	
	before(:each) do
		Synco::Disk.unmount(target_path)
	end
	
	after(:each) do
		Synco::Disk.unmount(target_path)
	end
	
	it 'should mount and backup to an attached USB stick' do
		script = Synco::Script.build do |script|
			script.method = Synco::Methods::RSyncSnapshot.new
			
			script.master = :source
			
			script.server(:source) do |server|
				server.root = master_path
			end
			
			script.server(:destination) do |server|
				server.mountpoint = target_path
				server.root = target_path
				
				server.on(:prepare) do
					target_server.run "synco", "mount", target_server.mountpoint, 'TEST'
				end
				
				# Runs after all directories have been successfully backed up.
				server.on(:success) do
					run "synco", "rotate", chdir: server.root
					run "synco", "prune", chdir: server.root
				end
				
				server.on(:finish) do
					target_server.run "synco", "unmount", target_server.mountpoint
				end
			end
			
			script.backup('.')
		end
		
		Synco::Runner.new(script).call
		
		Synco::Disk.mount(target_path, 'TEST')
		
		expect(Fingerprint).to be_identical(master_path, File.join(target_path, Synco::LATEST_NAME))
	end
end
