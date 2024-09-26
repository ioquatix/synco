#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

require "synco/scope"
require "synco/methods/scp"

require "synco/backup_script_context"

describe Synco::Methods::SCP do
	include_context Synco::BackupScriptContext
	
	with "explicit configuration" do
		let(:test_server) {ENV.fetch("TEST_SERVER", "localhost")}
		
		let(:script) {Synco::Script.new}
		let(:master_server) {Synco::Server.new("localhost", root: master_path)}
		let(:target_server) {Synco::Server.new(test_server, root: target_path)}
		
		let(:group) {Process::Group.new}
		let(:script_scope) {Synco::ScriptScope.new(script, group)}
		let(:sync_scope) {Synco::TargetScope.new(script_scope, target_server)}
		
		let(:directory) {Synco::Directory.new(".", arguments: ["--archive"])}
		let(:directory_scope) {Synco::DirectoryScope.new(sync_scope, directory)}
		
		let(:method) {subject.new}
		
		# This example shows all the state which goes into one single method invocation:
		it "should copy files from master to target" do
			script.instance_variable_set(:@master_server, master_server)
			script.instance_variable_set(:@current_server, master_server)
			
			expect(directory_scope.master_server).not.to be == nil
			expect(directory_scope.target_server).not.to be == nil
			expect(directory_scope.current_server).not.to be == nil

			group.wait do
				Fiber.new do
					method.call(directory_scope)
				end.resume
			end
			
			expect(Fingerprint).to be(:identical?, master_path, target_path)
		end
	end
	
	it "should build a script with desired configuration" do
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
				Console::Event::Failure.for(exception).emit(self)
			end
		end
		
		expect(script.events).to be(:include?, :failure)
		
		Synco::Runner.new(script).call
		
		expect(Fingerprint).to be(:identical?, master_path, target_path)
	end
end
