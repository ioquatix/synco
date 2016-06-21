
require 'mapping'
require 'shellwords'

module LSync
	# Join a sequence of arguments together to form a executable command.
	class Arguments < Mapping::Model
		map_identity String
		
		map(Symbol, &:to_s)
		map(Pathname, &:to_s)
		
		map(Array) do |items|
			items.compact.collect{|object| map(object)}
		end
		
		def shelljoin(*arguments)
			Shellwords.join(map(arguments))
		end
		
		def self.arguments
			@arguments ||= self.new
		end
		
		def self.map(*arguments)
			@arguments.map(*arguments)
		end
		
		def self.[](arguments)
			self.new.map(arguments)
		end
	end
end
