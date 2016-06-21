# LSync

LSync is a tool for scripted synchronization and backups. It provides a custom Ruby
DSL for describing complex backup and synchronization tasks. It is designed to give
maximum flexibility while reducing the complexity of describing complex multi-server
setups. For examples please see the main [project page][1].

[1]: http://www.codeotaku.com/projects/lsync/index

* Single and multi-server data synchronization.
* Incremental backups both locally and remotely.
* Backup staging and coordination.
* Backup verification using `Fingerprint`.
* Data backup redundancy controlled via DNS.

[![Build Status](https://secure.travis-ci.org/ioquatix/lsync.png)](http://travis-ci.org/ioquatix/lsync)
[![Code Climate](https://codeclimate.com/github/ioquatix/lsync.png)](https://codeclimate.com/github/ioquatix/lsync)
[![Coverage Status](https://coveralls.io/repos/ioquatix/lsync/badge.svg)](https://coveralls.io/r/ioquatix/lsync)

## Installation

Add this line to your application's Gemfile:

	gem 'lsync'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install lsync

## Usage

LSync imposes a particular structure regarding the organisation of backup scripts:
Backup scripts involve a set of servers and directories. A server is a logical unit 
where files are available or stored. Directories are specific places within servers.

A simple backup script might look something like this:

	#!/usr/bin/env ruby

	require 'lsync'
	require 'lsync/shells/ssh'
	require 'lsync/methods/rsync'

	LSync::run_script do |script|
		script.method = LSync::Methods::RSync.new(:push, :arguments => ["--archive", "--delete"])
		
		# Set :src to be the master server
		script.master = :src
		
		server(:src) do |server|
			server.host = "server.example.com"
			server.root = "/"
		end
		
		server(:dst) do |server|
			server.host = "backup.example.com"
			server.root = "/"
		end
		
		backup('etc', 'var', 'srv', 'home')
	end

### ZFS Snapshots

*This part of LSync is still under heavy development*

LSync can manage synchronization and backups of ZFS partitions. However, to use the standard tools, it is necessary to enable `zfs_admin_snapshot`, in `/etc/modprobe.d/zfs.conf`:

	options zfs zfs_admin_snapshot=1

Propagate user permissions for the ZFS partition:

	sudo zfs allow -ld -u `whoami` create,mount,send,receive,snapshot tank/test

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2015, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
