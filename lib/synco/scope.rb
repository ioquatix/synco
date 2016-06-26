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

require_relative 'script'

require 'process/group'

require 'logger'
require 'delegate'

module Synco
	class CommandFailure < RuntimeError
		def initialize(command, status)
			@command = command
			@status = status
			
			super "Command #{command.inspect} failed: #{status}!"
		end
		
		attr :command
		attr :status
	end
	
	class Runner
		def initialize(*scripts, loggger: nil)
			@scripts = scripts
			
			@logger = logger || Logger.new($stderr).tap{|logger| logger.formatter = CompactFormatter.new}
		end
		
		attr :scripts
		attr :logger
		
		def call
			start_time = Time.now
			
			logger.info "===== Starting at #{start_time} ====="
			
			Process::Group.wait do |group|
				@scripts.each do |script|
					Fiber.new do
						ScriptScope.new(script, @logger, group).call
					end.resume
				end
			end
		ensure
			end_time = Time.now
			logger.info "[Time]: (#{end_time - start_time}s)."
			logger.info "===== Finished backup at #{end_time} ====="
		end
	end
	
	class ScriptScope
		def initialize(script, logger, group)
			@script = script
			@logger = logger
			@group = group
			
			@current_server = ServerScope.new(@script.current_server, self)
			@master_server = ServerScope.new(@script.master_server, self, @current_server)
		end
		
		attr :script
		attr :logger
		attr :group
		attr :master_server
		attr :current_server
		
		def method
			@script.method
		end
		
		def call
			if @script.running_on_master?
				logger.info "We are the master server..."
			else
				logger.info "We are not the master server..."
				logger.info "Master server is #{@master}..."
			end

			@script.try(self) do
				# This allows events to run on the master server if specified, before running any backups.
				@master_server.try(self) do
					method.try(self) do
						logger.info "Running backups for server #{@current_server}..."
						
						run_servers(group)
					end
				end
			end
		end

		private

		def target_servers
			@script.servers.each do |name, server|
				# server is always a data destination, therefore server can't be @master_server:
				next if @master_server.eql?(server)
				
				yield ServerScope.new(server, self, @current_server)
			end
		end

		# This function runs the method for each directory and server combination specified.
		def run_servers(group)
			target_servers do |server|
				sync_scope = SyncScope.new(self, server)

				logger.info "===== Processing ====="
				logger.info "[Master]: #{master_server}"
				logger.info "[Target]: #{server}"
				
				server.try(sync_scope) do
					@script.directories.each do |directory|
						directory_scope = DirectoryScope.new(sync_scope, directory)

						logger.info "[Directory]: #{directory}"
						directory.try(directory_scope) do
							method.call(directory_scope)
						end
					end
				end
			end
		end
	end
	
	class LogPipe < DelegateClass(IO)
		def initialize(logger, level = :info)
			@input, @output = IO.pipe
			
			super(@output)
			
			@thread = Thread.new do
				@input.each{|line| logger.send(level, line.chomp!)}
			end
		end
		
		def close
			# Close the output pipe, we should never be writing to this anyway:
			@output.close
			
			# Wait for the thread to read everything and join:
			@thread.join
			
			# Close the input pipe because it's already closed on the remote end:
			@input.close
		end
	end
	
	class ServerScope < DelegateClass(Server)
		def initialize(server, script_scope, from = nil)
			super(server)
			
			@script_scope = script_scope
			@from = from
		end
		
		def logger
			@logger ||= @script_scope.logger
		end
		
		def group
			@group ||= @script_scope.group
		end
		
		def run(*command, from: @from, **options, &block)
			if options[:chdir].is_a? Symbol
				options[:chdir] = self.send(options[:chdir])
			end
			
			# We are invoking a command from the given server, so we need to use the shell to connect..
			if from and !from.same_host?(self)
				command = self.connection_command + ["--"] + command
				
				if chdir = options.delete(:chdir)
					command = ["synco", "--root", chdir, "spawn"] + command
				end
			end
			
			logger.info("shell") {[command, options]}
			
			options[:out] ||= LogPipe.new(logger)
			options[:err] ||= LogPipe.new(logger, :error)
			
			status = self.group.spawn(*command, **options)
			
			options[:out].close
			options[:err].close
			
			unless status.success?
				raise CommandFailure.new(command, status)
			end
		end
	end
	
	class SyncScope < DelegateClass(ScriptScope)
		def initialize(script_scope, target)
			super(script_scope)
			
			@target_server = ServerScope.new(target, script_scope, script_scope.current_server)
		end
		
		attr :target_server
	end
	
	class DirectoryScope < DelegateClass(SyncScope)
		def initialize(sync_scope, directory)
			super(sync_scope)
			
			@directory = directory
		end
		
		attr :directory
	end
end
