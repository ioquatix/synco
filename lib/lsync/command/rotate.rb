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

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require 'samovar'

require_relative '../method'

module LSync
	module Command
		class Rotate < Samovar::Command
				self.description = "Rotate a backup snapshot into a timestamped directory."
				
				options do
					option "--format <name>", "Set the name of the backup rotations, including strftime expansions.", default: BACKUP_NAME
					option "--latest <name>", "The name of the latest backup symlink.", default: LATEST_NAME
					option "--snapshot <name>", "The name of the in-progres backup snapshot.", default: SNAPSHOT_NAME
					
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
				
				def invoke(parent)
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
