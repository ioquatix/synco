#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "synco/directory"

describe Synco::Directory.new(".", arguments: ["--foo"]) do
	it "should have arguments" do
		expect(subject.arguments).to have_value(be == "--foo")
	end
	
	it "must be relative path" do
		expect do
			Synco::Directory.new("/var")
		end.to raise_exception(ArgumentError)
	end
end
