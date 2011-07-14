
module LSync
	
	# Basic event handling and delegation.
	module EventHandler
		# Register an event handler
		def on(event, &block)
			@events ||= {}

			@events[event] ||= []
			@events[event] << Proc.new(&block)
		end

		# Fire an event
		def fire(event, *args)
			if @events && @events[event]
				@events[event].each do |handler|
					handler.call(*args)
				end
			end
		end	
	end
	
end
