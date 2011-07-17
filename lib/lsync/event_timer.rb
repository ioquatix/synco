
require 'thread'

module LSync
	
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
		
		attr :thread
		
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
			
			@callback = Proc.new(&block)
			@processing = Mutex.new
		end
		
		def trigger!
			unless @timeout
				@timeout = Timeout.new(@max) { fire! }
			end
		end
		
		private
		def expired?(duration = nil)
			!@fired || ((Time.now - @fired) > duration)
		end
		
		def fire!
			@processing.synchronize do
				@timeout = nil
				
				@fired = Time.now
				@callback.call
			end
		end
		
		def join
			if @timeout
				@timeout.thread.join
			end
		end
	end
	
end