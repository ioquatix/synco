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
require 'process/group'
require 'fileutils'
require 'digest'

require 'synco/script'

RSpec.shared_context "backup script" do
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
	
	let(:tmp_path) {File.join(__dir__, 'tmp')}
	let(:master_path) {File.join(__dir__, 'tmp/master')}
	let(:target_path) {File.join(__dir__, 'tmp/target')}
	
	before(:each) do
		create_files(master_path, target_path)
	end
	
	after(:each) do
		FileUtils.rm_rf tmp_path
	end
end
