
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
			
			"[T+#{sprintf('%0.1f', diff).ljust(5)} #{severity.rjust(5)}] #{msg}\n"
		end
	end
end

class Logger
	include LSync::TeeHelper
end

