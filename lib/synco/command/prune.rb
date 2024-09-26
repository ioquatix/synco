# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require "samovar"

require "periodical/filter"

# Required for strptime
require "date"

module Synco
	module Command
		class Rotation
			include Comparable
			
			def initialize(path, time)
				@path = path
				@time = time
			end

			attr :time
			attr :path
			
			# Sort in reverse order by default
			def <=> other
				other.time <=> @time
			end
			
			def eql? other
				case other
				when Rotation
					@path.eql?(other.path)
				else
					@path.eql?(other.to_s)
				end
			end
			
			def hash
				@path.hash
			end
			
			def to_s
				@path
			end
		end
		
		class Prune < Samovar::Command
			self.description = "Prune old backups to reduce disk usage according to a given policy."
			
			options do
				option "--hourly <count>", "Set the number of hourly backups to keep.", default: 24, type: Integer
				option "--daily <count>", "Set the number of daily backups to keep.", default: 7*4, type: Integer
				option "--weekly <count>", "Set the number of weekly backups to keep.", default: 52, type: Integer
				option "--monthly <count>", "Set the number of monthly backups to keep.", default: 12*3, type: Integer
				option "--quarterly <count>", "Set the number of quaterly backups to keep.", default: 4*10, type: Integer
				option "--yearly <count>", "Set the number of yearly backups to keep.", default: 20, type: Integer
				
				option "--format <name>", "Set the name of the backup rotations, including strftime expansions.", default: BACKUP_NAME
				option "--latest <name>", "The name of the latest backup symlink.", default: LATEST_NAME
				
				option "--keep <new|old>", "Keep the younger or older backups within the same period division", default: "old"
				
				option "--dry", "Print out what would be done rather than doing it."
			end
			
			def policy
				policy = Periodical::Filter::Policy.new
				
				policy << Periodical::Filter::Hourly.new(@options[:hourly])
				policy << Periodical::Filter::Daily.new(@options[:daily])
				policy << Periodical::Filter::Weekly.new(@options[:weekly])
				policy << Periodical::Filter::Monthly.new(@options[:monthly])
				policy << Periodical::Filter::Quarterly.new(@options[:quarterly])
				policy << Periodical::Filter::Yearly.new(@options[:yearly])
				
				return policy
			end
			
			def current_backups
				backups = []
				
				Dir["*"].each do |path|
					next if path == @options[:latest]
					date_string = File.basename(path)
					
					begin
						backups << Rotation.new(path, DateTime.strptime(date_string, @options[:format]))
					rescue ArgumentError
						$stderr.puts "Skipping #{path}, error parsing #{date_string}: #{$!}"
					end
				end
				
				return backups
			end
			
			def dry?
				@options[:dry]
			end
			
			def print_rotation(keep, erase)
				puts "*** Rotating backups (DRY!) ***"
				puts "\tKeeping:"
				keep.sort.each { |backup| puts "\t\t#{backup.path}" }
				puts "\tErasing:"
				erase.sort.each { |backup| puts "\t\t#{backup.path}" }
			end
			
			def perform_rotation(keep, erase)
				puts "*** Rotating backups ***"
				erase.sort.each do |backup|
					puts "Erasing #{backup.path}..."
					$stdout.flush

					# Ensure that we can remove the backup
					system("chmod", "-R", "ug+rwX", backup.path)
					system("rm", "-rf", backup.path)
				end
			end
			
			def call
				backups = current_backups
				
				retain, erase = policy.filter(backups, keep: @options[:keep].to_sym, &:time)
				
				# We need to retain the latest backup regardless of policy
				if latest = @options[:latest] and File.exist?(latest)
					latest_path = File.readlink(options[:latest])
					latest_rotation = erase.find{|rotation| rotation.path == latest_path}
					
					if latest_rotation
						puts "Retaining latest backup #{latest_rotation}"
						erase.delete(latest_rotation)
						retain << latest_rotation
					end
				end

				if dry?
					print_rotation(retain, erase)
				elsif erase.any?
					perform_rotation(retain, erase)
				end
			end
		end
	end
end
