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

require 'yaml'
require 'socket'
require 'set'
require 'logger'

require_relative 'synco/version'
require_relative 'synco/script'
require_relative 'synco/scope'

require 'fileutils'
require 'optparse'

require 'lockfile'

module Synco
	# Run a prepared backup script using a lockfile.
	def self.run_script(*arguments, **options, &block)
		script = Synco::Script.build(*arguments, **options, &block)
		lockfile_path = $0 + ".lock"
		
		# script.on(:failure) do |exception|
		# 	logger.error{exception}
		# 	
		# 	raise
		# end
		
		Lockfile.new(lockfile_path, :retries => 0) do
			Runner.new(script).call
		end
	end
end
