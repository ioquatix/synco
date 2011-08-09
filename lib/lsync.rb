# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
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

require 'rubygems'

require 'yaml'
require 'socket'
require 'set'
require 'logger'

require 'lsync/version'
require 'lsync/script'
require 'lsync/tee_logger'

require 'fileutils'
require 'optparse'

require 'open-uri'
require 'lockfile'

module LSync

	# Run a prepared backup script using a lockfile.
	def self.run_script(options = {}, &block)
		script = LSync::Script.new(options, &block)
		lockfile_path = $0 + ".lock"

		script.on(:failure) do |error|
			LSync::log_error(error, logger)
		end
		
		begin
			Lockfile.new(lockfile_path, :retries => 0) do
				script.run!
			end
		rescue Lockfile::MaxTriesLockError
			raise LockError.new("Lockfile #{lockfile_path} could not be acquired.")
		end
	end
	
end
