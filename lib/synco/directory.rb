# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

require_relative "controller"

module Synco
	class AbsolutePathError < ArgumentError
	end
	
	# A specific directory which is relative to the root of a given server. Specific configuration details
	# such as excludes and other options may be specified.
	class Directory < Controller
		def initialize(path, arguments: [])
			if path.start_with?("/")
				raise AbsolutePathError.new("#{path} must be relative!")
			end
			
			super()
			
			@arguments = arguments
			@path = self.class.normalize(path)
		end
		
		attr :path
		attr :arguments
		
		def depth
			self.class.depth(@path)
		end

		def to_s
			@path
		end
		
		def self.normalize(path)
			path.end_with?("/") ? path : path + "/"
		end
		
		def self.depth(path)
			path.count("/")
		end
	end
end
