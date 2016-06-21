
class Array
	# Join a sequence of arguments together to form a executable command.
	def to_cmd
		collect{|v| v.to_cmd}
	end
end

class Pathname
	def to_cmd
		to_s
	end
end

class Symbol
	def to_cmd
		to_s
	end
end

class String
	def to_cmd
		self
	end
end
