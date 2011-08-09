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

module LSync
	# A helper to provide easy access to the TeeLogger functionality.
	module TeeHelper
		def tee(*loggers)
			return TeeLogger.new(self, *loggers)
		end
	end

	# The tee logger provides a simple split logging system where multiple logs may receive the same
	# messages. These logs can route messages to different destinations using different formatting.
	class TeeLogger
		def initialize(*loggers)
			@loggers = Set.new(loggers.flatten.compact)
		end

		attr :loggers

		def self.logger_methods
			Set.new(Logger.instance_methods) - Set.new(Object.instance_methods + %w(tee))
		end

		logger_methods.each do |method|
			define_method(method) do |*args|
				@loggers.each { |l| l.send(method, *args) }
			end
		end

		include TeeHelper
	end
	
	# A minimal log format that keeps track of the start time, and prints the minimal amount of information.
	class MinimalLogFormat
		def initialize
			@start_time = nil
		end
		
		def call(severity, time, progname, msg)
			@start_time ||= time
			diff = time - @start_time
			
			"[T+#{sprintf('%0.1f', diff).ljust(6)} #{severity.rjust(5)}] #{msg}\n"
		end
	end
end

class Logger
	include LSync::TeeHelper
end

