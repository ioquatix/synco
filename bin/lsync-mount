#!/usr/bin/env ruby

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

module Linux
	Commands = {
		"mount" => "mount",
		"unmount" => "umount"
	}

	DevicePaths = [
		"/dev/disk/by-label",
		"/dev/disk/by-uuid",
		"/dev"
	]
	
	def self.run(action, disk_name)
		action = ARGV[0]
		disk_name = ARGV[1]

		mountpoint = File.join('', 'mnt', disk_name)

		if (action == 'mountpoint')
			puts File.join(mountpoint, ARGV[2..-1])
		else
			puts "#{action.capitalize}ing #{mountpoint}..."
			system Commands[action], mountpoint

			if $?.exitstatus != 0 or $?.exitstatus != 3383
				exit 5
			end
		end
	end
end

module Darwin
	DISKUTIL = "diskutil"

	def self.get_disk_id(name)
		begin
			`diskutil list`.match(/#{name}\s*\*?[0-9]+\.[0-9]+ .B\s+(disk[0-9]s[0-9])$/)[1]
		rescue
			exit 5
		end
	end

	def self.run
		action = ARGV[0]
		disk_name = ARGV[1]
		
		if (action == 'mountpoint')
			puts File.join('', 'Volumes', disk_name, ARGV[2..-1])
		else
			system DISKUTIL, action, get_disk_id(disk_name)
		end
	end
end

class UnsupportedPlatformError < StandardError
end

platform = `uname`.chomp.downcase
case platform
when "darwin"
	Darwin.run
when "linux"
	Linux.run
else
	raise UnsupportedPlatformError.new("Platform #{platform} not supported.")
end
