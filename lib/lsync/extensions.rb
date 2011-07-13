
class Hash
	def keys_matching(p, &block)
		s = {}

		self.each do |k,v|
			next unless k.match(p)

			v = yield(v, k) if block_given?

			s[k] = v
		end

		return s
	end

	def collect_values
		each do |k,v|
			self[k] = yield v
		end
	end
end
