#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.

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

require "synco/script"
require "synco/methods/scp"

describe Synco::Script do
	it "should build a script with desired configuration" do
		script = Synco::Script.build do |script|
			script.server(:master) do |server|
			end
			
			script.server(:backup) do |server|
				server.root = "backup"
				
				server.on(:prepare) do
					run "synco", "mount", chdir: server.root
				end
			end
		end
		
		# After building, everything should be frozen..
		expect(script).to be(:frozen?)
		
		# We should have the two servers defined:
		expect(script.servers).to have_keys(:master, :backup)
		
		# We should have a single event for backup server:
		expect(script[:backup].events).to have_keys(:prepare)
	end
end
