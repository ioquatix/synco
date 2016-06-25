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

require_relative 'backup_script'

describe LSync::Methods::SCP do
	include_context "backup script"
	
	it 'should build a script with desired configuration' do
		script = LSync::Script.build do
			self.method = LSync::Methods::SCP.new
			
			server(:master) do
				self.root = File.join(__dir__, "tmp/master")
			end
			
			server(:target) do
				self.root = File.join(__dir__, "tmp/target")
			end
			
			copy(".")
			
			on(:failure) do |exception|
				logger.error{exception}
			end
		end
		
		expect(script.events).to include(:failure)
		
		LSync::Runner.new(script).call
		
		expect(File).to be_exist script[:target].root
		
		expect(Fingerprint).to be_identical(script[:master].root, script[:target].root)
	end
end
