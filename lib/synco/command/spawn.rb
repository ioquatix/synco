# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require "samovar"

module Synco
	module Command
		class Spawn < Samovar::Command
			self.description = "Run a command using the synco environment and root directory."
				
			split :argv, "Command to spawn."
				
			def call
				Process.exec(*@argv)
			end
		end
	end
end
