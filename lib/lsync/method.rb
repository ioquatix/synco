
require 'fileutils'
require 'pathname'
require 'lsync/run'
require 'lsync/event_handler'

module LSync
	
	# A backup method provides the interface to copy data from one system to another.
	class Method
		include EventHandler
		
		def initialize(options = {})
			@logger = options[:logger] || Logger.new(STDOUT)
		end

		attr :logger, true

		def run(master_server, target_server, directory)
		end

		def should_run?(master_server, current_server, target_server)
		end
	end
	
end
