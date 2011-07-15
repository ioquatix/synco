
module LSync
	module TeeHelper
		def tee(*loggers)
			return TeeLogger.new(self, *loggers)
		end
	end

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

