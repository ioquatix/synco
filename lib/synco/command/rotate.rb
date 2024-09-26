# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require "samovar"

require_relative "../method"

module Synco
	module Command
		class Rotate < Samovar::Command
			self.description = "Rotate a backup snapshot into a timestamped directory."
				
			options do
				option "--format <name>", "Set the name of the backup rotations, including strftime expansions.", default: BACKUP_NAME
				option "--latest <name>", "The name of the latest backup symlink.", default: LATEST_NAME
				option "--snapshot <name>", "The name of the in-progress backup snapshot.", default: SNAPSHOT_NAME
					
				# option "--timezone <name>", "The default timezone for backup timestamps.", default: BACKUP_TIMEZONE
			end
				
			def backup_timestamp
				timestamp = Time.now.utc
					
				#if timezone = @options[:timezone]
				#	timestamp = timestamp.in_time_zone(timezone)
				#end
					
				return timestamp
			end
				
			def backup_name
				backup_timestamp.strftime(@options[:format])
			end
				
			def call
				snapshot_name = @options[:snapshot]
				unless File.exist? snapshot_name
					$stderr.puts "Snapshot directory #{snapshot_name} does not exist!"
					exit(10)
				end
					
				rotated_name = backup_name
				if File.exist? rotated_name
					$stderr.puts "Destination rotation name #{rotated_name} already exists!"
					exit(20)
				end
					
				puts "Rotating #{snapshot_name} to #{rotated_name} in #{Dir.pwd}"
					
				# Move rotated dir
				FileUtils.mv(snapshot_name, rotated_name)

				# Recreate latest symlink
				latest_link = @options[:latest]
				if File.symlink?(latest_link)
					puts "Removing old latest link..."
					FileUtils.rm(latest_link)
				end

				puts "Creating latest symlink to #{rotated_name}"
				FileUtils.ln_s(rotated_name, latest_link)
			end
		end
	end
end
