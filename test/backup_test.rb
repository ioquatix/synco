#!/usr/bin/env ruby

require 'rubygems'

require 'fingerprint'
require 'rexec'

require 'test/unit'
require 'fileutils'
require 'digest'

LOG_FILE = "backup-test.log"

module TestSetup
	def self.create_files(master, copy)
		FileUtils.rm_rf master
		FileUtils.rm_rf copy
		
		FileUtils.mkdir_p master
		FileUtils.mkdir_p copy
		
		(1...10).each do |i|
			path = File.join(master, i.to_s)

			FileUtils.mkdir(path)

			text = Digest::MD5.hexdigest(i.to_s)

			File.open(File.join(path, i.to_s), "w") { |f| f.write(text) }
		end
	end
end

class TestSync < Test::Unit::TestCase
	def setup
		@master = Pathname.new("TestBackup-Master")
		@copy = Pathname.new("TestBackup-Copy")
		
		TestSetup.create_files(@master, @copy)
	end

	def teardown
		FileUtils.rm_rf @master
		FileUtils.rm_rf @copy
	end

	def test_sync
		RExec::Task.open(['ruby', 'local_sync.rb', @master, @copy], :passthrough => :all) do |task|
			task.wait
		end
		
		checker = Fingerprint::check_paths(@master, @copy) do |checksum, path|
			$stderr.puts "Incorrect checksum #{checksum} for path #{path}"
		end
		
		assert(checker.failures.size == 0, "File copy failures detected: #{checker.failures.inspect}!")
	end
end

class TestBackup < Test::Unit::TestCase
	def setup
		@master = Pathname.new("TestBackup-Master")
		@copy = Pathname.new("TestBackup-Copy")
		
		TestSetup.create_files(@master, @copy)
	end

	def teardown
		FileUtils.rm_rf @master
		FileUtils.rm_rf @copy
	end

	def test_sync
		RExec::Task.open(['ruby', 'local_backup.rb', @master, @copy], :passthrough => :all) do |task|
			task.wait
		end
		
		checker = Fingerprint::check_paths(@master, @copy + "latest") do |checksum, path|
			$stderr.puts "Incorrect checksum #{checksum} for path #{path}"
		end
		
		assert(checker.failures.size == 0, "File copy failures detected: #{checker.failures.inspect}!")
	end
end
