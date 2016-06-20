# Copyright, 2016, Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
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

require 'pathname'
require 'logger'

module LSync
	class Context
		def initialize(script, **options)
			@script = script
			
			@logger = script.logger || Logger.new($stderr)
			@options = options
		end
		
		attr :master
		attr :current
		
		attr :logger
		attr :options
		
		attr :controller
		
		def method
			@script.method
		end
		
		def servers
			@script.servers
		end
		
		def directories
			@script.directories
		end
		
		# Run the backup process for all servers and directories specified.
		def run!(**options)
			start_time = Time.now
			
			@logger.info "===== Starting backup at #{start_time} ====="

			@master = @script.find_master_server
			@current = @script.find_current_server

			if @master.local?
				@logger.info "We are the master server..."
			else
				@logger.info "We are not the master server..."
				@logger.info "Master server is #{@master}..."
			end

			@controller = ServerController.new(self, @logger, @master)
			
			Process::Group.wait do |group|
				run_controllers!(group)
			end
		ensure
			end_time = Time.now
			logger.info "[Time]: (#{end_time - start_time}s)."
			logger.info "===== Finished backup at #{end_time} ====="
		end
		
		def run_controllers!(group)
			@script.try(controller) do
				# This allows events to run on the master server if specified, before running any backups.
				master.try(controller) do
					method.try(controller) do
						logger.info "Running backups for server #{current}..."

						run_backups!
					end
				end
			end
		end

		# This function runs the method for each directory and server combination specified.
		def run_backups!
			servers.each do |name, server|
				# S is always a data destination, therefore s can't be @master
				next if server == @master

				next unless server.role?(options[:role] || :any)

				server_controller = CopyController.new(self, logger, master, server, current)

				# Skip servers that shouldn't be processed
				unless method.should_run?(server_controller)
					logger.info "===== Skipping ====="
					logger.info "[Master]: #{master}"
					logger.info "[Target]: #{server}"
					next
				end

				logger.info "===== Processing ====="
				logger.info "[Master]: #{master}"
				logger.info "[Target]: #{server}"
				
				server.try(server_controller) do
					directories.each do |directory|
						directory_controller = DirectoryController.new(self, logger, master, server, current, directory)

						logger.info "[Directory]: #{directory}"
						directory.try(directory_controller) do
							method.run(directory_controller)
						end
					end
				end
			end
		end
	end
end
