
module LSync

	# Provides a stack based exception handling mechanism.
	class Try
		def initialize(reraise = false, &block)
			@handlers = []

			try(false, &block)
		end

		def on(exception, &block)
			@handlers << [exception, Proc.new(&block)]
		end

		def error? (&block)
			on(Exception, &block)
		end

		def try(reraise = true, &block)
			tmp = @handlers
			@handlers = []

			begin
				yield self
			rescue Exception
				handled = false
				
				@handlers.reverse_each do |klass, proc|
					if $!.class <= klass
						proc.call($!)
						
						handled = true
					end
				end

				raise if reraise || !handled
			ensure
				@handlers = tmp
			end
		end
	end

	def self.try(reraise = false, &block)
		Try.new(reraise, &block)
	end

end
