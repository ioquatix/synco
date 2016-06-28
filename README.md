# Synco

Synco is a tool for scripted synchronization and backups. It provides a custom Ruby DSL for describing complex backup and synchronization tasks. It is designed to give maximum flexibility while reducing the complexity of describing complex multi-server setups. For examples please see the main [project page][1].

[1]: http://www.codeotaku.com/projects/synco/index

* Single and multi-server data synchronization.
* Incremental backups both locally and remotely.
* Backup staging and coordination.
* Backup verification using [Fingerprint](https://github.com/ioquatix/fingerprint).
* Data backup redundancy controlled via DNS.

[![Build Status](https://secure.travis-ci.org/ioquatix/synco.svg)](http://travis-ci.org/ioquatix/synco)
[![Code Climate](https://codeclimate.com/github/ioquatix/synco.svg)](https://codeclimate.com/github/ioquatix/synco)
[![Coverage Status](https://coveralls.io/repos/ioquatix/synco/badge.svg)](https://coveralls.io/r/ioquatix/synco)

## Installation

Add this line to your application's Gemfile:

	gem 'synco'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install synco

## Usage

Synco imposes a particular structure regarding the organisation of backup scripts: Backup scripts involve a set of servers and directories. A server is a logical unit where files are available or stored. Directories are specific places within servers.

A simple backup script might look something like this:

	#!/usr/bin/env ruby

	require 'synco'
	require 'synco/methods/rsync'

	Synco::run_script do |script|
		script.method = Synco::Methods::RSync.new
		
		server(:master) do |server|
			server.host = "server.example.com"
			server.root = "/"
		end
		
		server(:backup) do |server|
			server.host = "backup.example.com"
			server.root = "/"
		end
		
		backup('etc', 'var', 'srv', 'home')
	end

### RSync Snapshots

Building on the above backup, you can use `Synco::Methods::RSyncSnapshot` which supports snapshot based backups. It creates a snapshot into a sub-directory called `latest.snapshot` and uses RSync's `--link-dest` to hard-link files when unchanged. Finally, you are expected to rotate and prune these backups as required, using the `synco` command:

	server(:backup) do |server|
		server.host = "backup.example.com"
		server.root = "/"
		
		server.on(:success) do
			run 'synco', '--root', target_server.root, 'rotate'
			run 'synco', '--root', target_server.root, 'prune'
		end
	end

### Mounting Disks

Synco supports mounting disks before the backup begins and unmounting them after done.

	server(:destination) do |server|
		self.mountpoint = '/Volumes/Backups'
		self.root = File.join(server.mountpoint, 'Laptop')
		
		on(:prepare) do
			# Depending on the platform, you may need to specify the device too:
			run 'synco', 'mount', self.mountpoint #, '/dev/hd1'
		end
		
		on(:finish) do
			run 'synco', 'unmount', self.mountpoint
		end
	end

### Database Backups

If you'd like to dump data before running the backup, it's possible using the event handling mechanisms:

	server(:master) do |server|
		server.host = "server.example.com"
		server.root = "/"
		
		server.on(:prepare) do
			# Dump MySQL to /srv/mysql
			run '/etc/lsync/mysql-backup.sh', '/srv/mysql'
		end
	end

### Fingerprint Integration

It is possible to make a [cryptographic checksum of the data](https://github.com/ioquatix/fingerprint). On a filesystem that supports snapshots, you can do this before the data is copied. For traditional filesystems, you generally need to do this afterwards.

	server(:master) do |server|
		server.host = "server.example.com"
		server.root = "/"
		
		server.on(:success) do
			# Dump MySQL to /srv/mysql
			run 'fingerprint', '--root', target_server.root, 'analyze'
		end
	end

### ZFS Snapshots

*This part of Synco is still under heavy development*

Synco can manage synchronization and backups of ZFS partitions. However, to use the standard tools, it is necessary to enable `zfs_admin_snapshot`, in `/etc/modprobe.d/zfs.conf`:

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

Copyright, 2016, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

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
