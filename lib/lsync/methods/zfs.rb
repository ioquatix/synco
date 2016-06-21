# Copyright, 2016, Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'lsync/method'

module LSync
	module Methods
		class ZFS < Method
			def initialize(direction, *arguments, **options)
				super(options)

				@direction = direction
				
				@zfs = options.fetch(:zfs, 'zfs')
			end
			
		protected

			def configuration(controller, source_directory, destination_directory)
				local_server = nil
				remote_server = nil
				source = nil
				destination = nil

				if @direction == :push
					local_server = controller.master
					remote_server = controller.target

					destination = [remote_server.connection_command, @zfs, "recv", remote_server.full_path(destination_directory)]
					source = [@zfs, "send", "-rnv", local_server.full_path(source_directory)]
				else
					local_server = controller.target
					remote_server = controller.master

					source = [remote_server.connection_command, @zfs, "send", "-rnv", remote_server.full_path(source_directory)]
					destination = [@zfs, "recv", local_server.full_path(destination_directory)]
				end
				
				return local_server, remote_server, source, destination
			end
			
			def run_handler(controller, local_server, source, destination)
				# ssh remote_server zfs send remote_path | zfs receive local_path
				# zfs send local_path | ssh remote_server zfs recv remote_path
				Process::Group.wait do |group|
					input, output = IO.pipe
					
					group.run(*source.to_cmd, out: output) do |exit_status|
						raise CommandFailure.new(source) unless exit_status.success?
					end
					
					group.run(*destination.to_cmd, in: input) do |exit_status|
						raise CommandFailure.new(destination) unless exit_status.success?
					end
				end
			end
			
		public
			
			def run(controller)
				directory = controller.directory
				
				local_server, remote_server, source, destination = configuration(controller, controller.directory, controller.directory)
				
				run_handler(controller, local_server, source, destination)
			end
			
			def should_run?(controller)
				if @direction == :push
					return controller.current == controller.master
				elsif @direction == :pull
					return controller.target.local?
				else
					return false
				end
			end
		end
	end
end