# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008-2024, by Samuel Williams.

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require "samovar"

require_relative "../disk"

module Synco
	module Command
		class Mount < Samovar::Command
			self.description = "Mount a disk with the given name."
			
			one :path, "The disk mount point."
			one :name, "The symbolic name of the disk to mount, e.g. disk label."
			
			def call
				# We may not have permission to make this directory, but we should still try:
				FileUtils.mkpath(@path) rescue nil
				
				Disk.mount(@path, @name)
			end
		end
		
		class Unmount < Samovar::Command
			self.description = "Unmount a disk with the given name."
			
			one :path, "The disk mount point."
			
			def call
				Disk.unmount(@path)
			end
		end
	end
end
