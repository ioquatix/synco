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

require 'thread'

module LSync
	
	# Manages a callback that will be executed after a set duration.
	class Timeout
		def initialize(timeout, &block)
			@cancelled = false
			
			@thread = Thread.new do
				sleep timeout
				
				unless @cancelled
					yield
				end
			end
		end
		
		# The thread on which the timeout is being waited.
		attr :thread
		
		# Cancel the timeout if possible and ensure that the callback is not executed.
		def cancel!
			@cancelled = true
			@thread.exit
		end
	end
	
	# The EventTimer provides a simple time based callback mechanism in which events can be aggregated.
	# If the timer is triggered once, it will take at most max time for the callback to be triggered.
	class EventTimer
		# Times are measured in seconds.
		# Min specifies the minimum duration between callback invocations.
		# Max specifies the maximum duration between callback invocations.
		def initialize(max, &block)
			@max = max
			
			@fired = nil
			@timeout = nil
			
			@callback = block
			@processing = Mutex.new
		end
		
		# Trigger the event timer such that within the specified time, the callback will be fired.
		def trigger!
			unless @timeout
				@timeout = Timeout.new(@max) { fire! }
			end
		end
		
		private
		
		# Return true of the timeout has expired, e.g if it has not been fired within the given duration.
		def expired?(duration = nil)
			!@fired || ((Time.now - @fired) > duration)
		end
		
		# Fire the callback.
		def fire!
			@processing.synchronize do
				@timeout = nil
				
				@fired = Time.now
				@callback.call
			end
		end
		
		public
		
		# Wait for the timeout to complete nicely.
		def join
			if @timeout
				@timeout.thread.join
			end
		end
	end
	
end