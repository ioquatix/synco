# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'rainbow'
require 'shellwords'

module LSync
	class CompactFormatter
		def initialize(verbose: true)
			@start = Time.now
			@verbose = verbose
		end
		
		def time_offset_prefix
			offset = Time.now - @start
			minutes = (offset/60).floor
			seconds = (offset - (minutes*60))
			
			if minutes > 0
				"#{minutes}m#{seconds.floor}s"
			else
				"#{seconds.round(2)}s"
			end.rjust(6)
		end
		
		def chdir_string(options)
			if options[:chdir]
				" in #{options[:chdir]}"
			else
				""
			end
		end
		
		def format_command(arguments, buffer)
			arguments = arguments.dup
			
			environment = arguments.first.is_a?(Hash) ? arguments.shift : nil
			options = arguments.last.is_a?(Hash) ? arguments.pop : nil
			
			arguments = arguments.flatten.collect(&:to_s)
			
			buffer << Rainbow(Shellwords.join(arguments)).bright.blue
			
			if options
				buffer << chdir_string(options)
			end
			
			buffer << "\n"
			
			# if environment
			# 	environment.each do |key,value|
			# 		buffer << "\texport #{key}=#{value.dump}\n"
			# 	end
			# end
		end
		
		def format_exception(exception, buffer)
			buffer << Rainbow("#{exception.class}: #{exception}").bright.red << "\n"
			exception.backtrace.each do |line|
				buffer << "\t" << Rainbow(line).red << "\n"
			end
		end
		
		def format_line(message, severity)
			if severity == 'ERROR'
				Rainbow(message).red
			else
				message
			end
		end
		
		def call(severity, datetime, progname, message)
			buffer = []
			prefix = ""
			
			if @verbose
				prefix = time_offset_prefix
				buffer << Rainbow(prefix).cyan + ": "
				prefix = " " * (prefix.size) + "| " 
			end
			
			if progname == 'shell' and message.kind_of? Array
				format_command(message, buffer)
			elsif message.kind_of? Exception
				format_exception(message, buffer)
			else
				buffer << format_line(message, severity) << "\n"
			end
			
			result = buffer.join
			
			# This fancy regex indents lines correctly depending on the prefix:
			result.gsub!(/\n(?!$)/, "\n#{prefix}") unless prefix.empty?
			
			return result
		end
	end
end
