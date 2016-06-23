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

require 'process/group'
require 'delegate'

module LSync
	class ScriptScope
		def initialize(script, group)
			@script = script
			@group = group
			
			@current = ServerScope.new(self, @script.current)
			@master = ServerScope.new(self, @script.master, @current)
		end
		
		attr :script
		attr :group
		attr :master
		attr :current
		
		# Run the backup process for all servers and directories specified.
		def execute
			start_time = Time.now
			
			@logger.info "===== Starting at #{start_time} ====="

			if running_on_master?
				@logger.info "We are the master server..."
			else
				@logger.info "We are not the master server..."
				@logger.info "Master server is #{@master}..."
			end
			
			run_script(group)
		ensure
			end_time = Time.now
			logger.info "[Time]: (#{end_time - start_time}s)."
			logger.info "===== Finished backup at #{end_time} ====="
		end
		
		private
		
		def run_script(group)
			@script.try(self) do
				# This allows events to run on the master server if specified, before running any backups.
				master.try(self) do
					method.try(self) do
						logger.info "Running backups for server #{current}..."
						
						run_servers(group)
					end
				end
			end
		end

		# This function runs the method for each directory and server combination specified.
		def run_servers(group)
			servers.each do |name, server|
				# S is always a data destination, therefore s can't be @master
				next if server.equal?(@master)

				copy_controller = CopyController.new(self, master, server, current)

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
	
	class ServerScope < DelegateClass(ScriptScope)
		def initialize(script_scope, server, from = nil)
			super(script_scope)
			
			@server = server
			@from = from
		end
		
		attr :server
		attr :from
		
		def run(*command, **options, &block)
			# We are invoking a command from the given server, so we need to use the shell to connect..
			if @from
				command = @server.connection_command + ["--"] + command
				
				if chdir = options.delete(:chdir)
					chdir = @server.root if chdir == :root
					
					command = ["lsync", "--root", chdir, "spawn"] + command
				end
			end
			
			group.run(*command, **options) do |status|
				raise RuntimeError.new("Command #{command.inspect} failed #{status}!") unless status.success?
			end
		end
	end
	
	class DirectoryScope < DelegateClass(ScriptScope)
		def initialize(script_scope, target, directory)
			super(script_scope)
			
			@target = ServerScope.new(script_scope, target, script_scope.current)
			@directory = directory
		end
		
		attr :target
		attr :directory
	end
end
