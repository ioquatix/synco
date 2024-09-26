# Synco ![Development](https://github.com/ioquatix/synco/workflows/Development/badge.svg)

Synco is a tool for scripted synchronization and backups. It provides a custom Ruby DSL for describing backup and synchronization tasks involving one more more system and disk. It is designed to provide flexibility while reducing the complexity multi-server backups.

  - Single and multi-server data synchronization.
  - Incremental backups both locally and remotely.
  - Backup staging and coordination.
  - Backup verification using [Fingerprint](https://github.com/ioquatix/fingerprint).
  - Data backup redundancy controlled via DNS.

[![Development Status](https://github.com/ioquatix/synco/workflows/Test/badge.svg)](https://github.com/ioquatix/synco/actions?workflow=Test)

## Installation

Add this line to your application's Gemfile:

    gem 'synco'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install synco

## Usage

Synco imposes a particular structure regarding the organisation of backup scripts: Backup scripts involve a set of servers and directories. A server is a logical unit where files are available or stored. Directories are relative paths which are resolved relative to a server's root path.

A simple backup script might look something like this:

``` ruby
#!/usr/bin/env ruby

require 'synco'
require 'synco/methods/rsync'

Synco::run_script do |script|
	script.method = Synco::Methods::RSync.new(archive: true)
	
	server(:master) do |server|
		server.host = "server.example.com"
		server.root = "/"
	end
	
	server(:backup) do |server|
		server.host = "backup.example.com"
		server.root = "/tank/backups/server.example.com"
	end
	
	backup('etc', 'var', 'srv', 'home', 
		arguments: %W{--exclude cache/ --exclude tmp/}
	)
end
```

This will produce an identical copy using rsync of the specified directories. As an example `server.example.com:/etc` would be copied to `backup.example.com:/tank/backups/server.example.com/etc`.

### RSync Snapshots

Building on the above backup, you can use `Synco::Methods::RSyncSnapshot` which supports snapshot based backups. It creates a snapshot into a sub-directory called `latest.snapshot` and uses RSync's `--link-dest` to hard-link files when unchanged. Synco provides scripts to rotate and prune these backups as required, but you must invoke them as part of the script:

``` ruby
server(:backup) do |server|
	server.host = "backup.example.com"
	server.root = "/"
	
	server.on(:success) do
		run "synco", "rotate", chdir: target_server.root
		run "synco", "prune", chdir: target_server.root
	end
end
```

These commands can also be run from the command line.

``` 
rotate [--format <name>] [--latest <name>] [--snapshot <name>]
	Rotate a backup snapshot into a timestamped directory.

	[--format <name>]    Set the name of the backup rotations, including strftime expansions.  Default: %Y.%m.%d-%H.%M.%S
	[--latest <name>]    The name of the latest backup symlink.                                Default: latest           
	[--snapshot <name>]  The name of the in-progress backup snapshot.                          Default: latest.snapshot  

prune [--hourly <count>] [--daily <count>] [--weekly <count>] [--monthly <count>] [--quarterly <count>] [--yearly <count>] [--format <name>] [--latest <name>] [--keep <new|old>] [--dry]
	Prune old backups to reduce disk usage according to a given policy.

	[--hourly <count>]     Set the number of hourly backups to keep.                             Default: 24               
	[--daily <count>]      Set the number of daily backups to keep.                              Default: 28               
	[--weekly <count>]     Set the number of weekly backups to keep.                             Default: 52               
	[--monthly <count>]    Set the number of monthly backups to keep.                            Default: 36               
	[--quarterly <count>]  Set the number of quaterly backups to keep.                           Default: 40               
	[--yearly <count>]     Set the number of yearly backups to keep.                             Default: 20               
	[--format <name>]      Set the name of the backup rotations, including strftime expansions.  Default: %Y.%m.%d-%H.%M.%S
	[--latest <name>]      The name of the latest backup symlink.                                Default: latest           
	[--keep <new|old>]     Keep the younger or older backups within the same period division     Default: old              
	[--dry]                Print out what would be done rather than doing it.                  
```

### Mounting Disks

Synco supports mounting disks before the backup begins and unmounting them after done. The specifics of this process may require some adjustment based on your OS. For example on linux, `sudo` is used to invoke `mount` and `umount`.

``` ruby
server(:destination) do |server|
	self.mountpoint = '/mnt/backups'
	self.root = File.join(server.mountpoint, 'laptop')
	
	server.on(:prepare) do
		# synco mount uses labels, e.g. the disk partition has LABEL=backups
		target_server.run "synco", "mount", target_server.mountpoint, 'backups'
	end
	
	server.on(:finish) do
		target_server.run "synco", "unmount", target_server.mountpoint
	end
end
```

On Linux, you might want to create the file `/etc/sudoers.d/synco` with the following contents:

    %wheel ALL=(root) NOPASSWD: /bin/mount
    %wheel ALL=(root) NOPASSWD: /bin/umount

Please make sure you take the time to educate yourself on the security of such a setup.

### Database Backups

If you'd like to dump data before running the backup, it's possible using the event handling mechanisms:

``` ruby
server(:master) do |server|
	server.host = "server.example.com"
	server.root = "/"
	
	server.on(:prepare) do
		# Dump MySQL to /srv/mysql
		run '/etc/lsync/mysql-backup.sh'
	end
end
```

The exact contents of `mysql-backup.sh` will depend on your requirements, but here is an example:

``` bash
#!/usr/bin/env bash

BACKUP_DIR=/srv/mysql
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

databases=`mysql --user=backup -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|_test|_restore)"`

# http://stackoverflow.com/questions/451404/how-to-obtain-a-correct-dump-using-mysqldump-and-single-transaction-when-ddl-is
MYSQLDUMP_OPTIONS="--force --skip-opt --single-transaction --add-drop-table --create-options --quick --extended-insert --set-charset --disable-keys"

for db in $databases; do
	echo "Dumping database $db to $BACKUP_DIR/$db.sql.xz..."
	mysqldump --user=backup $MYSQLDUMP_OPTIONS --databases $db | xz > "$BACKUP_DIR/$db.sql.xz"
done
```

### Fingerprint Integration

It is possible to make a [cryptographic checksum of the data](https://github.com/ioquatix/fingerprint). On a filesystem that support immutable snapshots, you can do this before the data is copied. For traditional filesystems, you generally need to do this afterwards.

``` ruby
server(:master) do |server|
	server.host = "server.example.com"
	server.root = "/"
	
	server.on(:success) do
		# Run fingerprint on the backup data:
		run 'fingerprint', '--root', target_server.root, 'analyze'
	end
end
```

Fingerprint is used in many of the specs to verify file copies.

### ZFS Snapshots

*This part of Synco is still under heavy development*

Synco can manage synchronization and backups of ZFS partitions. However, to use the standard tools, it is necessary to enable `zfs_admin_snapshot`, in `/etc/modprobe.d/zfs.conf`:

    options zfs zfs_admin_snapshot=1

Propagate user permissions for the ZFS partition:

``` bash
sudo zfs allow -ld -u `whoami` create,mount,send,receive,snapshot tank/test
```

### Backup staging

Synco in a previous life supported backup staging. However, at this time it's not available except in a very limited form: backup scripts which use `Synco.run_script` use explicit locking so that it's not possible to run the same backup at the same time. In the future, staging sequential and parallel backups will be added.

### DNS Failover

**This behaviour is not well tested**

Synco uses DNS to resolve the master server. This allows for bi-directional synchronization and other interesting setups.

Firstly, a backup script defaults to the server with the name `:master` as the master, where data is replicated FROM.

However, it is possible instead to specify a hostname, e.g. `primary.example.com`. Then, specify several servers, e.g. `s01.example.com`, `s02.example.com` and so on:

``` ruby
Synco::run_script do |script|
	script.method = Synco::Methods::RSync.new(archive: true)
	
	script.master = "primary.example.com"
	
	server("s01.example.com") do |server|
		server.root = "/"
	end
	
	server("s02.example.com") do |server|
		server.root = "/"
	end
	
	backup('srv/http', 
		arguments: %W{--exclude cache/ --exclude tmp/}
	)
end
```

When you run the script, the behaviour will depend on whether `primary.example.com` points to `s01.example.com` or `s02.example.com`. The data will always be copied from the master server to the other servers.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
