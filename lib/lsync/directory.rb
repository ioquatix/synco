
require 'lsync/event_handler'
require 'pathname'

class Pathname
	# Split a pathname up based on the individual path components.
	def components
		return to_s.split(SEPARATOR_PAT)
	end

	# Add a trailing slash to the path if it doesn't already exist.
	def normalize_trailing_slash
		if to_s.match(/\/$/)
			return self
		else
			return self.class.new(to_s + "/")
		end
	end

	# Returns the number of path components in a normalised fashion.
	#
	# We need to work with a cleanpath to get an accurate depth:
	#	"", "/" => 0
	#	"bob" => 1
	#	"bob/dole" => 2
	#	"/bob/dole" => 2
	def depth
		bits = cleanpath.to_s.split(SEPARATOR_PAT)

		bits.delete("")
		bits.delete(".")

		return bits.size
	end
end

module LSync

	# A specific directory which is relative to the root of a given server. Specific configuration details
	# such as excludes and other options may be specified.
	class Directory
		include EventHandler
		
		def initialize(path)
			@path = Pathname.new(path).cleanpath.normalize_trailing_slash
			@options = {:arguments => []}
		end

		attr :path
		attr :options

		# Exclude a specific shell glob pattern.
		def exclude(pattern)
			# RSync specific... need to figure out if there is a good way to do this generally.
			@options[:arguments] += ["--exclude", pattern]
		end

		# A string representation of the path for logging.
		def to_s
			@path.to_s
		end
	end

end