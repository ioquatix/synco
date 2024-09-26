# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2024, by Samuel Williams.

require_relative "../shell"

module Synco
	module Shells
		# SSH shell provides access to a remote server using SSH.
		class SSH < Shell
			def default_command
				["ssh"]
			end
			
			def initialize(*command, arguments: [], port: nil, key: nil, user: nil, batch_mode: nil, **options)
				if port
					arguments << "-p" << port
				end
				
				if key
					arguments << "-i" << key
				end
				
				if user
					arguments << "-l" << user
				end
				
				unless batch_mode.nil?
					arguments << "-o" << "BatchMode=#{batch_mode ? 'yes' : 'no'}"
				end
				
				super
			end
		end
	end
end
