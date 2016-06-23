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
require 'lsync/methods/scp'

module LSync::ShellSpec
	describe LSync::Methods::SCP do
		let(:test_server) {ENV.fetch('TEST_SERVER', 'localhost')}
		
		let(:source_path) {File.join(__dir__, "source")}
		let(:destination_path) {"/tmp/lsync-test"}
		
		let(:script) {LSync::Script.new}
		let(:logger) {Logger.new($stderr)}
		let(:master) {LSync::Server.new('localhost', root: source_path)}
		let(:target) {LSync::Server.new(test_server, root: destination_path)}
		
		let(:script_scope) {LSync::ScriptScope.new(script, group)}
		let(:directory_controller) {LSync::DirectoryController.new(script, logger, master, target, master, "")}
		
		it 'should copy files from master to target' do
			result = subject.run(directory_controller)
			
			expect(result).to be_success
		end
	end
end
