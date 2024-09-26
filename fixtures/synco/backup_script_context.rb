#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

require "fingerprint"
require "process/group"
require "fileutils"
require "digest"
require "tmpdir"

require "synco/scope"
require "synco/script"

module Synco
	SYNCO_PATH = File.expand_path("../../bin/synco", __dir__)
	
	BackupScriptContext = Sus::Shared("backup script") do
		let(:synco_path) {SYNCO_PATH}
		
		def create_files(master_path, target_path)
			FileUtils.rm_rf master_path
			FileUtils.rm_rf target_path
			
			FileUtils.mkdir_p master_path
			FileUtils.mkdir_p target_path
			
			(1...10).each do |i|
				path = File.join(master_path, i.to_s)

				FileUtils.mkdir(path)

				text = Digest::MD5.hexdigest(i.to_s)

				File.open(File.join(path, i.to_s), "w") { |f| f.write(text) }
			end
		end
		
		let(:tmp_path) {File.join(@root, "tmp")}
		let(:master_path) {File.join(@root, "master")}
		let(:target_path) {File.join(@root, "target")}
		
		around do |&block|
			Dir.mktmpdir do |root|
				@root = root
				
				create_files(master_path, target_path)
				
				super(&block)
			end
		end
	end
end
