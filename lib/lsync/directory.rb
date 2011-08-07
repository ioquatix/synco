# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'lsync/error'
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
	
	class AbsolutePathError < Error
	end
	
	# A specific directory which is relative to the root of a given server. Specific configuration details
	# such as excludes and other options may be specified.
	class Directory
		include EventHandler
		
		def initialize(path)
			@path = Pathname.new(path).cleanpath.normalize_trailing_slash
			@options = {:arguments => []}
			
			if @path.absolute?
				raise AbsolutePathError.new("Path #{path} may not be absolute!", :path => path)
			end
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