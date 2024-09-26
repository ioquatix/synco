# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

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
