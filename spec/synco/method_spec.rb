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

require 'synco/scope'
require 'synco/methods/scp'

require_relative 'backup_script'

describe Synco::Methods::SCP do
	include_context "backup script"
	
	let(:test_server) {ENV.fetch('TEST_SERVER', 'localhost')}
	
	let(:script) {Synco::Script.new}
	let(:logger) {Logger.new($stderr)}
	let(:master_server) {Synco::Server.new('localhost', root: master_path)}
	let(:target_server) {Synco::Server.new(test_server, root: target_path)}
	
	let(:group) {Process::Group.new}
	let(:script_scope) {Synco::ScriptScope.new(script, logger, group)}
	let(:sync_scope) {Synco::TargetScope.new(script_scope, target_server)}
	
	let(:directory) {Synco::Directory.new(".")}
	let(:directory_scope) {Synco::DirectoryScope.new(sync_scope, directory)}
	
	# This example shows all the state which goes into one single method invocation:
	it 'should copy files from master to target' do
		script.instance_variable_set(:@master_server, master_server)
		script.instance_variable_set(:@current_server, master_server)
		
		expect(directory_scope.master_server).to_not be == nil
		expect(directory_scope.target_server).to_not be == nil
		expect(directory_scope.current_server).to_not be == nil

		result = nil

		group.wait do
			Fiber.new do
				subject.call(directory_scope)
			end.resume
		end
		
		expect(Fingerprint).to be_identical(master_path, target_path)
	end
end
