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
require 'synco/script'
require 'synco/scope'
require 'synco/methods/scp'

require_relative 'backup_script'

RSpec.describe Synco::Methods::SCP do
	include_context "backup script"
	
	it 'should build a script with desired configuration' do
		script = Synco::Script.build do |script|
			script.method = Synco::Methods::SCP.new
			
			script.server(:master) do |server|
				server.root = master_path
			end
			
			script.server(:target) do |server|
				server.root = target_path
			end
			
			script.copy(".")
			
			script.on(:failure) do |exception|
				logger.error{exception}
			end
		end
		
		expect(script.events).to include(:failure)
		
		Synco::Runner.new(script).call
		
		expect(Fingerprint).to be_identical(master_path, target_path)
	end
end
