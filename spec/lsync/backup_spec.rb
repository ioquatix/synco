#!/usr/bin/env rspec

# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'fingerprint'
require 'rexec'
require 'fileutils'
require 'digest'

require 'lsync/script'

module LSync::BackupSpec
	LOG_FILE = "backup-test.log"
	
	describe LSync::Script do
		def create_files(master, copy)
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
		
		before(:each) do
			@master = Pathname.new("tmp/master")
			@copy = Pathname.new("tmp/copy")
			
			create_files(@master, @copy)
		end
		
		after(:each) do
			FileUtils.rm_rf @master
			FileUtils.rm_rf @copy
		end
		
		LOCAL_SYNC_SCRIPT = File.join(__dir__, 'local_sync.rb')
		
		it "should synchronize files" do
			RExec::Task.open(['ruby', LOCAL_SYNC_SCRIPT, @master, @copy], :passthrough => :all) do |task|
				task.wait
			end
			
			failures = 0
			
			checker = Fingerprint::check_paths(@master, @copy) do |record, name, message|
				failures += 1
				$stderr.puts "Path #{record.path} different"
			end
			
			expect(failures).to be == 0
		end
		
		LOCAL_BACKUP_SCRIPT = File.join(__dir__, 'local_backup.rb')
		
		it "should backup files" do
			RExec::Task.open(['ruby', LOCAL_BACKUP_SCRIPT, @master, @copy], :passthrough => :all) do |task|
				task.wait
			end
			
			failures = 0
			checker = Fingerprint::check_paths(@master, @copy + "latest") do |record, name, message|
				failures += 1
				$stderr.puts "Path #{record.path} different"
			end
			
			expect(failures).to be == 0
		end
	end
end
