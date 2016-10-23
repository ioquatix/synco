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

module Synco
	# Depending on how you have things set up, you'll probably want to add
	# %wheel ALL=(root) NOPASSWD: /bin/mount
	# %wheel ALL=(root) NOPASSWD: /bin/umount
	# to /etc/sudoers.d/synco
	module LinuxDisk
		def self.available?(disk_name)
			File.exist?("/dev/disk/by-label/#{disk_name}")
		end
		
		def self.mount(path, disk_name = nil)
			if disk_name
				system("sudo", "mount", "-L", disk_name, path)
			else
				system("sudo", "mount", path)
			end
		end
		
		def self.unmount(path)
			system("sudo", "umount", path)
		end
	end

	module DarwinDisk
		DISKUTIL = "diskutil"
		
		def self.available?(disk_name)
			system(DISKUTIL, "list", disk_name)
		end
		
		def self.mount(path, disk_name = nil)
			disk_name ||= File.basename(path)
			
			system(DISKUTIL, "mount", "-mountPoint", path, disk_name)
		end
		
		def self.unmount(path)
			system(DISKUTIL, "unmount", path)
		end
	end
	
	case RUBY_PLATFORM
	when /darwin/
		Disk = DarwinDisk
	when /linux/
		Disk = LinuxDisk
	end
end
