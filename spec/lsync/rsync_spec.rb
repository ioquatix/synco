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
require 'lsync/methods/rsync'

describe LSync::Methods::RSync do
	it 'should copy files using rsync' do
		script = LSync::Script.build(master: :source) do
			self.method = LSync::Methods::RSyncSnapshot.new
			
			server(:source) do
				self.root = File.join(__dir__, 'source')
			end
			
			server(:backup) do
				self.root = File.join(__dir__, 'destination')
			end
			
			copy(".")
		end
		
		LSync::Runner.new(script).call
		
		expect(File).to be_exist script[:backup].root
	end
	
	it 'should copy files using rsync snapshot' do
		script = LSync::Script.build(master: :source) do
			self.method = LSync::Methods::RSyncSnapshot.new
			
			server(:source) do
				self.root = File.join(__dir__, 'source')
			end
			
			server(:backup) do
				self.root = File.join(__dir__, 'destination-rsyncsnapshot')
				
				on(:success) do
					target_server.run "lsync", "rotate", chdir: :root
					target_server.run "lsync", "prune", chdir: :root
				end
			end
			
			copy(".")
		end
		
		LSync::Runner.new(script).call
		
		expect(File).to be_exist script[:backup].root
	end

end
	