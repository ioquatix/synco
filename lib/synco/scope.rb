# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2024, by Samuel Williams.

require_relative "script"

require "process/group"

require "console"
require "delegate"

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
		def initialize(*scripts)
			@scripts = scripts
		end
		
		attr :scripts
		
		def call
			Console.info(self, "Running scripts...")
			
			Process::Group.wait do |group|
				@scripts.each do |script|
					Fiber.new do
						ScriptScope.new(script, group).call
					end.resume
				end
			end
		rescue => error
			Console::Event::Failure.for(error).emit(self)
			raise
		ensure
			Console.info(self, "Finished running scripts.")
		end
	end
	
	class ScriptScope
		def initialize(script, group)
			@script = script
			@group = group
			
			@current_server = ServerScope.new(@script.current_server, self)
			@master_server = ServerScope.new(@script.master_server, self, @current_server)
		end
		
		attr :script
		attr :group
		attr :master_server
		attr :current_server
		
		def method
			@script.method
		end
		
		def call
			if @script.running_on_master?
				Console.info(self, "We are the master server...")
			else
				Console.info(self, "We are not the master server...", master: @master)
			end
			
			@script.try(self) do
				# This allows events to run on the master server if specified, before running any backups.
				
				@master_server.try(master_target_server) do
					method.try(self) do
						Console.info(self, "Running backups...", server: @current_server)
						
						run_servers(group)
					end
				end
			end
		end

		private
		
		def master_target_server
			TargetScope.new(self, @master_server)
		end

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
				sync_scope = TargetScope.new(self, server)
				
				Console.info(self, "Running script...", master: @master_server, target: server)
				
				server.try(sync_scope) do
					@script.directories.each do |directory|
						directory_scope = DirectoryScope.new(sync_scope, directory)
						
						Console.info(self, "Processing directory...", directory: directory)
						
						directory.try(directory_scope) do
							method.call(directory_scope)
						end
					end
				end
			end
		end
	end
	
	class LogPipe < DelegateClass(IO)
		def initialize(logger: Console, level: :info)
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
		
		def group
			@group ||= @script_scope.group
		end
		
		def run(*command, from: @from, **options)
			# We are invoking a command from the given server, so we need to use the shell to connect..
			if from and !from.same_host?(self)
				if chdir = options.delete(:chdir)
					command = ["synco", "--root", chdir, "spawn"] + command
				end
				
				command = self.connection_command + ["--"] + command
			end
			
			Console::Event::Spawn.for(*command, **options).emit(self)
			
			options[:out] ||= LogPipe.new
			options[:err] ||= LogPipe.new(level: :error)
			
			status = self.group.spawn(*command, **options)
			
			Console.info(self, "Command completed.", status: status)
			
			options[:out].close
			options[:err].close
			
			unless status.success?
				raise CommandFailure.new(command, status)
			end
		end
	end
	
	class TargetScope < DelegateClass(ScriptScope)
		def initialize(script_scope, target)
			super(script_scope)
			
			@target_server = ServerScope.new(target, script_scope, script_scope.current_server)
		end
		
		def run(...)
			@target_server.run(...)
		end
		
		attr :target_server
	end
	
	class DirectoryScope < DelegateClass(TargetScope)
		def initialize(sync_scope, directory)
			super(sync_scope)
			
			@directory = directory
		end
		
		attr :directory
	end
end
