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

require 'logger'
require 'lsync/script'
require 'lsync/scope'
require 'lsync/methods/scp'

describe LSync::Methods::RSyncSnapshot do
	xit 'should mount and backup to an attached USB stick' do
		script = LSync::Script.build do |script|
			script.method = LSync::Methods::RSyncSnapshot.new
			
			script.server(:source) do |server|
				server.root = '/Users/samuel/'
			end
			
			script.server(:destination) do |server|
				server.mountpoint = '/Volumes/TEST/'
				server.root = server.mountpoint + 'samuel'
				
				server.on(:prepare) do
					run "lsync", "mount", self.mountpoint
				end
				
				# Runs after all directories have been successfully backed up.
				server.on(:success) do
					run "lsync", "rotate", chdir: server.root
					run "lsync", "prune", chdir: server.root
				end
				
				server.on(:finish) do
					run "lsync", "unmount", server.mountpoint
				end
			end
			
			script.backup('Desktop')
		end
		
		LSync::Runner.new(script).call
	end
end
