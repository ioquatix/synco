# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require "samovar"

require_relative "command/spawn"
require_relative "command/rotate"
require_relative "command/prune"
require_relative "command/disk"

require_relative "version"

module Synco
	module Command
		class Top < Samovar::Command
			self.description = "A backup and synchronizatio tool."
			
			options do
				option "--root <path>", "Work in the given root directory."
				option "-h/--help", "Print out help information."
				option "-v/--version", "Print out the application version."
			end
			
			def chdir(&block)
				if root = @options[:root]
					Dir.chdir(root, &block)
				else
					yield
				end
			end
			
			nested :command, {
				"spawn" => Spawn,
				"rotate" => Rotate,
				"prune" => Prune,
				"mount" => Mount,
				"unmount" => Unmount
			}
			
			def call
				if @options[:version]
					puts "synco v#{Synco::VERSION}"
				elsif @options[:help] or @command.nil?
					print_usage(program_name)
				else
					chdir do
						@command.call
					end
				end
			end
		end
	end
end
