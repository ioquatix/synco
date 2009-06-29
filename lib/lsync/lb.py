#!/usr/bin/env python
# -*- Mode: Python; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*-

"""Link-Backup
Copyright (c) 2004 Scott Ludwig
http://www.scottlu.com

Link-Backup is a backup utility that creates hard links between a series
of backed-up trees, and intelligently handles renames, moves, and
duplicate files without additional storage or transfer.

Transfer occurs over standard i/o locally or remotely between a client and
server instance of this script. Remote backups rely on the secure remote
shell program ssh.

viewlb.cgi, a simple web based viewer of backups made by link-backup, is
also available from the link-backup page.

http://www.scottlu.com/Content/Link-Backup.html

Usage:

lb [options] srcdir dstdir
lb [options] user@host:srcdir dstdir
lb [options] srcdir user@host:dstdir

Source or dest can be remote. Backups are dated with the following entries:

dstdir/YYYY.MM.DD-HH.MM:SS/tree/        backed up file tree
dstdir/YYYY.MM.DD-HH.MM:SS/log          logfile

Options:

    --verify          Run rsync with --dry-run to cross-verify
    --numeric-ids     Keep uid/gid values instead of mapping; requires root
    --minutes <mins>  Only run for <mins> minutes. Incremental backup.
    --showfiles       Don't backup, only list relative path files needing
                      backup
    --catalogonly     Update catalog only
    --filelist <- or file> Specify filelist. Files relative to srcdir.
    --lock            Ensure only one backup to a given dest will run at a time
    --verbose         Show what is happening

Comments:

Link-Backup tracks unique file instances in a tree and creates a backup that
while identical in structure, ensures that no file is duplicated unnecessarily.
Files that are moved, renamed, or duplicated won't cause additional storage or
transfer. dstdir/.catalog is a catalog of all unique file instances; backup
trees hard-link to the catalog. If a backup tree would be identical to the
previous backup tree, it won't be needlessly created.

How it works:

The src sends a file list to the dst. First dst updates the catalog by checking
to see if it knows about each file. If not, the file is retrieved from the src
and a new catalog entry is made:

    For each file:
    1. Check to see if the file path + file stat is present in the last tree.
    2. If not, ask for md5sum from the src. See if md5sum+stat is in the
       catalog.
    3. If not, see if md5sum only is in the catalog. If so copy catalog entry,
       rename with md5sum+new stat
    4. If not, request file from src, make new catalog entry.
    
Catalog files are named by md5sum+stats and stored in flat directories. Once
complete, a tree is created that mirrors the src by hardlinking to the catalog.

Example 1:

python lb.py pictures pictures-backup

Makes a new backup of pictures in pictures-backup.

Example 2:

python lb.py pictures me@fluffy:~/pictures-backup

Backs up on remote machine fluffy instead of locally.

Example 3:

python lb.py --minutes 240 pictures me@remote:~/pictures-backup

Same as above except for 240 minutes only. This is useful if backing up over
the internet only during specific times (at night for example). Does what it
can in 240 minutes. If the catalog update completes, a tree is created
hardlinked to the catalog.

Example 4:
python lb.py --showfiles pictures pictures-backup | \
python lb.py --filelist - pictures pictures-backup

Same as example #1.

Example 5:

1)
python lb.py --showfiles pictures me@remote:~/pictures-backup | \
python lb.py --filelist - pictures me@laptop:~/pictures-transfer

2)
python lb.py --catalogonly pictures-transfer me@remote:~/pictures-backup

3)
python lb.py pictures me@remote:~/pictures-backup

If the difference between pictures and pictures-backup (for example) is too
large for internet backup, the steps above can be used. Step 1 transfers only
the differences to a laptop. Step 2 is at the location of machine "remote" and
is initiated from the laptop to machine "remote". Step 3 is back at the source
and will do a backup and notice all the files are present in the remote catalog,
and will build the tree.

Note the source in step 2 could be more perfectly specified as the backup tree
created underneath the pictures-transfer directory, although it is not necessary
since only the catalog is being updated (however it would be a speedup).
 
History:

v 0.83 17/Apr/2009 Samel Williams http://www.oriontransfer.co.nz/
  - Collaboration with Scott to fix a bug that caused a crash
    when a file changed (stat -> fstat)

v 0.82 20/Oct/2008 Samuel Williams http://www.oriontransfer.co.nz/
  - Removed --ssh-(x) options in favor of rsync style -e '...' style,
    this makes the command compatible with rsync style syntax.

v 0.81 6/Sep/2008 Samuel Williams http://www.oriontransfer.co.nz/
  - Added mode-line and #! line
  - Fixed parsing of command line arguments that contain spaces to match rsync
    (shlex parsing)
  - Fixed escaping of ssh strings so that they get passed correctly

v 0.8 12/23/2006 scottlu
  - allow backups to occur while files are changing
  - minor --verify command bug
  - added --verbose logging to tree building

v 0.7 09/02/2006 scottlu
  - Ignore pipe, socket, and device file types
  - Added --ssh-i to select ssh id file to use (see ssh -i) (Damien Mascord)
  - Added --ssh-C to perform ssh compression (see ssh -C) (David Precious)
  - Added --ssh-p to specify remote port (see ssh -p) (David Precious)

v 0.6 06/17/2006 scottlu
  - Ignore broken symlinks and other failed stats during filelist creation
    (David Precious)
  - Added --lock, which ensures only one backup to a given dest can occur
    at a time (Joe Beda)

v 0.5 04/15/2006 scottlu
  - Added 'latest' link from Joe Beda http://eightypercent.net (thanks Joe!)
  - Fixed --verify. It wasn't specifying the remote machine (I rarely use
    verify but sometimes it is nice to sanity check backups)

v 0.4 11/14/2004 scottlu
  - Changed a central catalog design with trees hardlinking to the catalog.
    This way catalog updating can be incremental.
  - Removed filemaps - not required any longer
  - Add catalog logging as well as backup logging.
  - Added incremental backup feature --minutes <minutes>
  - Make md5hash calculation incremental so a timeout doesn't waste time
  - Created 0.3-0.4.py for 0.3 to 0.4 upgrading
  - Added --showfiles, shows differences between src and dst
  - Added --catalogonly, updates catalog only, doesn't create tree
  - Added --filelist, specifies file list to use instead of tree
  - Removed --rmempty
  - Added --verbose

v 0.3 9/10/2004 scottlu
  - Added backup stat query methods
  - Changed log file format
  - Added viewlb.cgi, a web interface for viewing backups
  - added gzip compression of filemap
  - added --numeric-ids

v 0.2 8/28/2004 scottlu
  - filemap format change
  - added --rmempty
  - added --verify to run rsync in verify mode
  - added uid/gid mapping by default unless --numeric-ids is specified

v 0.1 8/19/2004 scottlu
  - Fully working backup, hardlinking between trees

License:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import os
import sys
import cPickle
from os.path import join
import time
import stat
import md5
import shutil
import tempfile
import struct
import re
import glob
import fcntl
import shlex

fd_send = None
fd_recv = None
pickler = None
unpickler = None
date_format = '%Y.%m.%d-%H.%M.%S'

MODE = 0
SIZE = 1
MTIME = 2
UID = 3
GID = 4
CHMOD_BITS = int('6777', 8)

def send_object(object):
    global pickler, fd_send
    pickler.dump(object)
    fd_send.flush()

def recv_object():
    global unpickler
    return unpickler.load()

def init_io(send, recv):
    global fd_send, fd_recv, pickler, unpickler
    fd_send = send
    fd_recv = recv
    pickler = cPickle.Pickler(fd_send, 1)
    unpickler = cPickle.Unpickler(fd_recv)

def verbose_log(s):
    if have_option('--verbose'):
        sys.stderr.write('%s\n' % s)

class Log:
    def __init__(self, logfile, mode):
        self.mode = mode
        try:
            self.logfile = file(os.path.abspath(logfile), self.mode)
        except:
            self.logfile = None
        self.re = re.compile(r'^(?P<time>....\...\...\-..\...\...)\: (?P<message>.*)$')

    def __del__(self):
        if self.logfile:
            self.logfile.close()

    def write(self, message):
        if not self.logfile or self.mode == 'rt':
            return

        try:
            strtime = time.strftime(date_format, time.localtime())
            self.logfile.write('%s: %s\n' % (strtime, message))
            self.logfile.flush()
        except:
            pass

    def nextline(self):
        if not self.logfile or self.mode == 'at':
            return

        line = self.logfile.readline()
        if len(line) == 0:
            return None
        m = self.re.match(line)
        return (time.strptime(m.group('time'), date_format), m.group('message'))

class Catalog:
    """Central store for files of different hash/stat combinations
    Backup trees hard link to the catalog. The catalog can be updated
    incrementally. A backup tree is not created until the catalog is
    up to date.
    """
    def __init__(self, path):
        self.path = os.path.abspath(path)
        self.lenbase = len('%s%s' % (self.path, os.sep))
        self.logpath = join(self.path, 'log')
        if not os.path.exists(self.path):
            os.mkdir(self.path)
            os.mkdir(self.logpath)
            for n in xrange(256):
                os.mkdir(join(self.path, '%03d' % n))

    def get_logfiles(self):
        list = []
        for item in os.listdir(self.logpath):
            s = os.stat(join(self.logpath, item))
            if stat.S_ISDIR(s.st_mode):
                continue
            try:
                datestr = item.rstrip('.log')
                time.strptime(datestr, date_format)
                list.append(datestr)
            except:
                pass
        list.sort()
        return [(time.strptime(datestr, date_format), join(self.logpath, '%s.log' % datestr)) for datestr in list]

    def parse_log(self, logpath_abs):
        log = Log(logpath_abs, 'rt')
        parse = []
        while True:
            line = log.nextline()
            if line == None:
                break
            elif line[1].startswith('+++'):
                continue
            elif line[1].startswith('copy from: '):
                tT = line[0]
                fromT = line[1][11:]
                forT = ''
                line = log.nextline()
                if line[1].startswith('copy for: '):
                    forT = line[1][10:]
                parse.append(('copy', tT, fromT, forT))
            elif line[1].startswith('new from: '):
                tT = line[0]
                fromT = line[1][10:]
                forT = ''
                line = log.nextline()
                if line[1].startswith('new for: '):
                    forT = line[1][9:]
                parse.append(('new', tT, fromT, forT))
        return parse

    def file_from_hash(self, md5):
        subdir = join(self.path, '%03d' % (hash(md5) & 255))
        files = glob.glob1(subdir, '%s*' % md5)
        if len(files) > 0:
            return join(subdir, files[0])
        return None

    def file_from_hashstat(self, md5, s):
        filepath_abs = self.getfilepath(md5, s)
        if os.path.exists(filepath_abs):
            return filepath_abs
        return None

    def getfilepath(self, md5, s):
        mdate = time.strftime(date_format, time.localtime(s[MTIME]))
        fn = '%s-%s-%08x-%05x-%04d-%04d' % (md5, mdate, s[SIZE], s[MODE] & CHMOD_BITS, s[UID], s[GID])
        return join(join(self.path, '%03d' % (hash(md5) & 255)), fn)

    def update(self, filelist, treepath_last, end_time):
        # This is the slow (and expensive!) bandwidth eating portion
        # of link-backup. If --minutes is specified, don't go beyond
        # the minutes specified. 

        # For each file see if exists in the catalog; if not copy it
        # if the md5 exists or download it

        datestr = time.strftime(date_format, time.localtime())
        log = Log(join(self.logpath, '%s.log' % datestr), 'wt')
        dl_seconds = 0
        dl_size = 0
        md5hashes = [None for n in xrange(len(filelist))]
        log.write('+++begin+++')
        for n in xrange(len(filelist)):
            # Only files

            filepath_rel, s = filelist[n]
            if stat.S_ISDIR(s[MODE]):
                continue

            # If stat equal we don't need a hash for this file

            if treepath_last and is_stat_equal(join(treepath_last, filepath_rel), s):
                verbose_log('dst: found file %s' % filelist[n][0])
                continue

            # Get the md5hash for this file

            verbose_log('dst: request hash for %s' % filelist[n][0])
            send_object(n)
            md5hashes[n] = recv_object()
            if not md5hashes[n]:
                verbose_log('dst: did not receive hash?')
                send_object(False)
                continue

            # File already present? Skip.
            if self.file_from_hashstat(md5hashes[n], s):
                verbose_log('dst: file present already %s' % filelist[n][0])
                send_object(False)
                continue

            # File not present. Copy locally or from the source
            fd, tmpfilepath_abs = tempfile.mkstemp(dir=self.path)
            filepath_abs = self.getfilepath(md5hashes[n], s)
            try:
                copyfile_abs = self.file_from_hash(md5hashes[n])
                if copyfile_abs:
                    # Found same file with different stats. Requires a copy
                    verbose_log('dst: using file with same hash %s' % filelist[n][0])
                    send_object(False)
                    shutil.copyfile(copyfile_abs, tmpfilepath_abs)
                    log.write('copy from: %s' % filepath_abs[self.lenbase:])
                    log.write('copy for: %s' % filepath_rel)
                else:
                    # Enough time for this file?
                    if end_time != 0 and dl_seconds != 0:
                        est_seconds = s[SIZE] / (dl_size / dl_seconds)
                        if time.time() + est_seconds >= end_time:
                            verbose_log('dst: timeout')
                            send_object(False)
                            raise
                   
                    # Time downloads to understand average download rate and use as
                    # an estimator of a given file's download time
                    verbose_log('dst: requesting file %s' % filelist[n][0])
                    dl_time_start = time.time()

                    # Copy from source
                    # The chunks are sized independent from stats for robustness
                    # Stat is resent to have most up to date copy
                    # Recalc the md5 hash along the way so it is right
                    send_object(True)
                    m = md5.new()
                    while True:
                        readcount = struct.unpack('!i', fd_recv.read(4))[0]
                        if readcount == 0:
                            break
                        if readcount < 0:
                            raise 'Error reading file'
                        bytes = fd_recv.read(readcount)
                        m.update(bytes)
                        os.write(fd, bytes)

                    # Delta accumulator
                    dl_seconds += time.time() - dl_time_start
                    os.fsync(fd)
                    dl_size += os.fstat(fd).st_size

                    # File might of changed during the update
                    # Update has and size and check to see if it already
                    # exists in the catalog
                    if md5hashes[n] != m.hexdigest():
                        verbose_log('dst: file changed during copy %s' % filelist[n][0])
                        md5hashes[n] = m.hexdigest()
                        s[SIZE] = os.fstat(fd).st_size
                        filelist[n] = (filepath_rel, s)
                        if self.file_from_hashstat(md5hashes[n], s):
                            verbose_log('dst: file already in catalog %s' % filelist[n][0])
                            os.close(fd)
                            os.remove(tempfilepath_abs)
                            continue
                            
                    log.write('new from: %s' % filepath_abs[self.lenbase:])
                    log.write('new for: %s' % filepath_rel)

            except:
                os.close(fd)
                os.remove(tmpfilepath_abs)
                send_object(-1)
                log.write('+++end+++')

                return False, dl_size, md5hashes

            # Rename and set file stats
            
            os.close(fd)
            os.utime(tmpfilepath_abs, (s[MTIME], s[MTIME]))
            os.chown(tmpfilepath_abs, s[UID], s[GID])
            os.rename(tmpfilepath_abs, filepath_abs)
            os.chmod(filepath_abs, s[MODE] & CHMOD_BITS)

        # Done with file requests

        verbose_log('dst: catalog update done')
        send_object(-1)
        log.write('+++end+++')
        return True, dl_size, md5hashes

    def get_showfiles(self, filelist, treepath_last):

        # Get hashes for new files. If file doesn't exist in old backup with same
        # stat, we need ask the client for a hash

        md5requests = []
        for n in xrange(len(filelist)):
            # Only files

            filepath_rel, s = filelist[n]
            if stat.S_ISDIR(s[MODE]):
                continue

            # If stat equal we don't need a hash for this file

            if treepath_last and is_stat_equal(join(treepath_last, filepath_rel), s):
                continue

            # Need hash for this file

            md5requests.append(n)

        # Retrieve hashes

        send_object(md5requests)
        md5hashes = recv_object()
        if len(md5hashes) != len(md5requests):
            raise AssertionError, 'Hash count mismatch'

        # Make one sorted list to eliminate duplicates
        # Check if already present in catalog

        md5sort = [(md5requests[n], md5hashes[n]) for n in xrange(len(md5hashes)) if not self.file_from_hash(md5hashes[n])]
        def sortme(a, b):
            if a[1] == b[1]:
                return 0
            if a[1] > b[1]:
                return 1
            return -1
        md5sort.sort(sortme)

        # Eliminate duplicates and return

        showfiles = []
        md5 = None
        for n in xrange(len(md5sort)):
            if md5 == md5sort[n][1]:
                continue
            md5 = md5sort[n][1]
            showfiles.append(md5sort[n][0])
        return showfiles

# Backup

class Backup:
    """Represents a dated backup.
    """
    def __init__(self, path):
        self.path = os.path.abspath(path)
        self.logpath_abs = join(self.path, 'log')
        self.treepath = join(self.path, 'tree')
        if not os.path.exists(self.treepath):
            os.mkdir(self.treepath)

    def parse_log(self):
        log = Log(self.logpath_abs, 'rt')
        parse = []
        while True:
            line = log.nextline()
            if line == None:
                break
            if line[1] == '+++end+++' or line[1] == '+++begin+++':
                continue
            if line[1].startswith('new: '):
                parse.append(('new', line[1][5:]))
            elif line[1].startswith('copy: '):
                parse.append(('copy', line[1][6:]))
            elif line[1].startswith('link: '):
                parse.append(('link', line[1][6:]))

        return parse

    def get_date(self):
        return time.strptime(self.get_dirname(), date_format)

    def get_dirname(self):
        return os.path.basename(self.path)

    def get_treepath(self):
        return self.treepath

    def get_files_since(self, backup_last, catalog):
        # Get files added to the catalog since last tree was built

        tlast = 0
        if backup_last:
            tlast = time.mktime(backup_last.get_date())
        filessince = {}
        for tm, logfile_abs in catalog.get_logfiles():
            if time.mktime(tm) < tlast:
                continue
            for item in catalog.parse_log(logfile_abs):
                filessince[item[3]] = item[0]
        return filessince

    def build_tree(self, backup_last, filelist, md5hashes, catalog):
        """All files are present and can be found either in the
        previous backup or the catalog. Just build the structure.
        """

        treepath_last = None
        if backup_last:
            treepath_last = backup_last.get_treepath()
        filessince = self.get_files_since(backup_last, catalog)
        log = Log(self.logpath_abs, 'at')
        log.write('+++begin+++')
        verbose_log('dst: creating tree %s' % self.treepath)

        # Create directories (they are in depth last order)
        # Set permissions later
        verbose_log('dst: making directories...')
        for filepath_rel, s in filelist:
            if stat.S_ISDIR(s[MODE]):
                verbose_log('dst: making dir %s' % filepath_rel)
                dirpath_abs = join(self.treepath, filepath_rel)
                os.mkdir(dirpath_abs)

        # Link in files
        verbose_log('dst: linking files...')
        for n in xrange(len(filelist)):

            # Skip dirs
            filepath_rel, s = filelist[n]
            if stat.S_ISDIR(s[MODE]):
                continue
            verbose_log('dst: inspecting file %s' % filepath_rel)

            # If there is no hash, it's in the last backup, otherwise it's
            # in the catalog
            if not md5hashes[n]:
                verbose_log('dst: found in last backup: %s' % filepath_rel)
                linkpath_abs = join(treepath_last, filepath_rel)
            else:
                verbose_log('dst: found in catalog: %s' % filepath_rel)
                linkpath_abs = catalog.file_from_hashstat(md5hashes[n], s)

                # Only log files new to the catalog since last tree. This
                # ensures file renames, dups, moves etc don't show up as new
                # in the tree log
                if filessince.has_key(filepath_rel):
                    log.write('%s: %s' % (filessince[filepath_rel], filepath_rel))
                else:
                    log.write('link: %s' % filepath_rel)

            # Hard-link the file
            verbose_log('dst: hardlinking %s to %s' % (join(self.treepath, filepath_rel), linkpath_abs))
            os.link(linkpath_abs, join(self.treepath, filepath_rel))

        # Set permissions for directories depth-first.
        verbose_log('dst: setting permissions on directories...')
        for n in xrange(len(filelist) - 1, -1, -1):
            dirpath_rel, s = filelist[n]
            if stat.S_ISDIR(s[MODE]):
                verbose_log('dst: setting permissions on: %s' % dirpath_rel)
                dirpath_abs = join(self.treepath, dirpath_rel)
                os.utime(dirpath_abs, (s[MTIME], s[MTIME]))
                os.chown(dirpath_abs, s[UID], s[GID])
                os.chmod(dirpath_abs, s[MODE] & CHMOD_BITS)

        verbose_log('dst: done creating tree %s' % self.treepath)
        log.write('+++end+++')

# Manager

class Manager:
    """Manages Backup instances
    """
    def __init__(self, path):
        self.path = os.path.abspath(path)
        if not os.path.exists(self.path):
            os.mkdir(self.path)
        self.catalog = Catalog(join(self.path, '.catalog'))

    def get_path(self):
        return self.path

    def new_backup(self):
        dirpath = join(self.path, time.strftime(date_format, time.localtime()))
        os.mkdir(dirpath)
        return Backup(dirpath)

    def delete_backup(self, backup):
        dirpath_abs = join(self.path, backup.get_dirname())
        if os.path.exists(dirpath_abs):
            for root, dirs, files in os.walk(dirpath_abs, topdown=False):
                for name in files:
                    os.remove(join(root, name))
                for name in dirs:
                    os.rmdir(join(root, name))
            os.rmdir(dirpath_abs)

    def get_backup(self, backup):
        return Backup(join(self.path, backup))

    def get_backups(self):
        list = []
        for item in os.listdir(self.path):
            s = os.stat(join(self.path, item))
            if not stat.S_ISDIR(s.st_mode):
                continue
            try:
                time.strptime(item, date_format)
                list.append(item)
            except:
                pass
        list.sort()
        return [Backup(join(self.path, item)) for item in list]

# Helpers

def dump_arg(x):
    s = '"'
    for c in x:
        if c in '\\$"`':
            s = s + '\\'
        s = s + c
    s = s + '"'
    return s

def start_server(src, dst, is_source):
    # Command line for server

    cmd1 = "python -c 'import sys;import cPickle;exec(cPickle.Unpickler(sys.stdin).load())' --server"
    if is_source:
        cmd1 = "%s --source" % cmd1
    for arg in sys.argv[1:-2]:
        cmd1 = '%s %s' % (cmd1, arg)
    cmd1 = "%s %s %s" % (cmd1, dump_arg(src['string']), dump_arg(dst['string']))

    # Remote?

    addr = dst
    if is_source:
        addr = src

    # Add ssh and args if remote
    if addr['remote']:
        ssh_args = '%s %s' % (addr['remote'], dump_arg(cmd1))
        if have_option('-e'):
                cmd2 = '%s %s' % (get_option_value('-e'), ssh_args)
        else:
                cmd2 = 'ssh %s' % ssh_args
    else:
        cmd2 = cmd1

    # Start and pass this code
    verbose_log('command: %s' % cmd2)
    fdin, fdout = os.popen2(cmd2, mode='b')
    init_io(fdin, fdout)
    f = open(sys.argv[0])
    send_object(f.read())
    f.close()

def is_mode_ok(mode):
    if stat.S_ISBLK(mode):
        return False
    if stat.S_ISCHR(mode):
        return False
    if stat.S_ISFIFO(mode):
        return False
    if stat.S_ISSOCK(mode):
        return False
    return True

def build_filelist_from_tree(treepath):
    class ListBuilder:
        def __init__(self, basepath):
            self.lenbase = len('%s%s' % (basepath, os.sep))

        def callback(self, arg, dirpath, filelist):
            for file in filelist:
                # Sometimes a stat may fail, like if there are broken
                # symlinks in the file system
                try:
                    # Collect stat values instead of stat objects. It's 6
                    # times smaller (measured) and mutuable
                    # (for uid/gid mapping at the dest)
                    filepath = join(dirpath, file)
                    s = os.stat(filepath)
                    if not is_mode_ok(s.st_mode):
                        continue
                    arg.append((filepath[self.lenbase:], [s.st_mode, s.st_size, s.st_mtime, s.st_uid, s.st_gid]))
                except:
                    pass

    treepath_abs = os.path.abspath(treepath)
    filelist = []
    os.path.walk(treepath_abs, ListBuilder(treepath_abs).callback, filelist)
    return filelist

def build_filelist_from_file(treepath, file):
    filelist = []
    for line in file.readlines():
        filepath_rel = line.rstrip('\n')
        s = os.stat(join(treepath, filepath_rel))
        if not is_mode_ok(s.st_mode):
            continue
        filelist.append((filepath_rel, [s.st_mode, s.st_size, s.st_mtime, s.st_uid, s.st_gid]))
    return filelist

def build_filelist(treepath):
    verbose_log('building filelist...')
    for n in xrange(len(sys.argv)):
        if sys.argv[n] == '--filelist':
            if sys.argv[n + 1] == '-':
                return build_filelist_from_file(treepath, sys.stdin)
            else:
                file = open(sys.argv[n + 1])
                filelist = build_filelist_from_file(treepath, file)
                file.close()
                return filelist
    return build_filelist_from_tree(treepath)

def build_uidgidmap(filelist):
    """Build a map of uid's to names and gid's to names
    so mapping can occur at the destination
    """
    import pwd
    import grp
    uidname_map = {}
    gidname_map = {}
    for filepath_rel, s in filelist:
        if not uidname_map.has_key(s[UID]):
            try:
                uidname_map[s[UID]] = pwd.getpwuid(s[UID])[0]
            except:
                uidname_map[s[UID]] = str(s[UID])
        if not gidname_map.has_key(s[GID]):
            try:
                gidname_map[s[GID]] = grp.getgrgid(s[GID])[0]
            except:
                gidname_map[s[GID]] = str(s[GID])
    return uidname_map, gidname_map

def map_uidgid(filelist, idname_map):
    """Fix up uid / gid to dest values
    """

    # If root and --numeric-ids specified, keep the numeric
    # ids

    if os.getuid() == 0 and have_option('--numeric-ids'):
        return

    # First build a uid->uid map. If not root, valid
    # uid mapping is only current user. If root, attempt
    # to map uid, if that fails keep the uid.

    import pwd
    import grp

    uid_user = os.getuid()
    uidname_map = idname_map[0]
    uiduid_map = {}
    for uid_source in uidname_map.keys():
        if uid_user == 0:
            try:
                uid_dest = pwd.getpwnam(uidname_map[uid_source])[2]
                uiduid_map[uid_source] = uid_dest
            except:
                uiduid_map[uid_source] = uid_source
        else:
            uiduid_map[uid_source] = uid_user

    # Build gid->gid map. If not root, valid gid mapping is any group
    # this user is a part of. First build a list of valid name->gids
    # mappings

    gid_user = os.getgid()
    gid_name = grp.getgrgid(gid_user)[0]
    namegid_map = {}
    for group in grp.getgrall():
        if uid_user == 0 or gid_name in group[3]:
            namegid_map[group[0]] = group[2]

    # Now build a gid map to valid gids for this user

    gidname_map = idname_map[1]
    gidgid_map = {}
    for gid_source in gidname_map.keys():
        gid_sourcename = gidname_map[gid_source]
        if namegid_map.has_key(gid_sourcename):
            gidgid_map[gid_source] = namegid_map[gid_sourcename]
        else:
            gidgid_map[gid_source] = gid_user

    # Now map filelist entries

    for filepath_rel, s in filelist:
        # Continue if nothing to do. Unlikely in the mapping case

        if uiduid_map[s[UID]] == s[UID] and gidgid_map[s[GID]] == s[GID]:
            continue

        # Map entries

        s[UID] = uiduid_map[s[UID]]
        s[GID] = gidgid_map[s[GID]]

def serve_files(treepath, filelist):
    """Serve requested files.
    """
    global fd_recv

    while True:
        # Which file?

        n = recv_object()
        if n == -1:
            break

        # Calc hash and return it

        verbose_log('src: calc hash for %s' % filelist[n][0])
        filepath_rel, s = filelist[n]
        filepath_abs = join(treepath, filepath_rel)
        try:
            f = open(filepath_abs)
            m = md5.new()
            while True:
                bytes = f.read(1024 * 1024)
                if len(bytes) == 0:
                    break
                m.update(bytes)
            f.close()
            send_object(m.hexdigest())
        except:
            verbose_log('src: error calcing hash for %s' % filelist[n][0])
            send_object(None)

        # False means don't need the file

        if not recv_object():
            verbose_log('src: skipping file %s' % filelist[n][0])
            continue

        # Send size with data chunks in case the file is changing
        # while this occurs

        verbose_log('src: sending file %s' % filelist[n][0])
        try:
            f = open(filepath_abs)
            while True:
                bytes = f.read(1024 * 1024)
                fd_send.write(struct.pack('!i', len(bytes)))
                if len(bytes) == 0:
                    break
                fd_send.write(bytes)
            fd_send.flush()
            f.close()
        except:
            verbose_log('src: error sending file %s' % filelist[n][0])
            fd_send.write(struct.pack('!i', -1))

        verbose_log('src: send complete %s' % filelist[n][0])

def serve_hashes(treepath, filelist):
    """Serve requested hashes
    """
    hashrequests = recv_object()
    hashlist = []
    for n in xrange(len(hashrequests)):
        filepath_rel, s = filelist[hashrequests[n]]
        filepath_abs = join(treepath, filepath_rel)
        f = open(filepath_abs)
        m = md5.new()
        while True:
            bytes = f.read(1024 * 1024)
            if len(bytes) == 0:
                break
            m.update(bytes)
        f.close()
        hashlist.append(m.hexdigest())
    send_object(hashlist)

def is_stat_equal(filepath_abs, s):
    try:
        s2 = os.stat(filepath_abs)
        if (s[MODE] & CHMOD_BITS) == (s2.st_mode & CHMOD_BITS) and s[SIZE] == s2.st_size and s[MTIME] == s2.st_mtime and s[UID] == s2.st_uid and s[GID] == s2.st_gid:
            return True
    except:
        pass
    return False

def is_tree_equal(filelist, treepath_last):
    verbose_log('checking for need to build tree...')
    if not treepath_last:
        verbose_log('tree not equal: no last tree!')
        return False
    filelist_old = build_filelist_from_tree(treepath_last)
    if len(filelist) != len(filelist_old):
        verbose_log('tree not equal: filelists different sizes!')
        return False
    dict_new = dict(filelist)
    dict_old = dict(filelist_old)
    for key in dict_new.keys():
        different = False
        if not dict_old.has_key(key):
            different = True
        else:
            s_old = dict_old[key]
            s_new = dict_new[key]
            different = False
            if stat.S_ISDIR(s_old[MODE]):
                if s_old[MODE] != s_new[MODE] or s_old[MTIME] != s_new[MTIME] or s_old[UID] != s_new[UID] or s_old[GID] != s_new[GID]:
                    different = True
            else:
                if s_old != s_new:
                    different = True
        if different:
            verbose_log('tree not equal: stats different %s' % key)
            if dict_old.has_key(key):
                verbose_log('old %s' % str(dict_old[key]))
            verbose_log('new %s' % str(dict_new[key]))
            return False
    verbose_log('no need to build tree - it would be identical to the last tree');
    return True

def execute(src, dst, is_source):
    if is_source:
        # Sending side
        # Create filelist, calc name map, send both

        srcpath = os.path.abspath(os.path.expanduser(src['path']))
        filelist = build_filelist(srcpath)
        send_object(filelist)
        idname_map = build_uidgidmap(filelist)
        send_object(idname_map)

        # Which command

        if have_option('--showfiles'):
            serve_hashes(srcpath, filelist)
        else:
            serve_files(srcpath, filelist)

        results = recv_object()
        subdir = recv_object()
    else:
        # Receiving side
        # Recv filelist and name mapping, perform uid/gid mapping
        filelist = recv_object()
        idname_map = recv_object()
        map_uidgid(filelist, idname_map)
        manager = Manager(os.path.expanduser(dst['path']))
        catalog = manager.catalog
        backups = manager.get_backups()
        treepath_last = None
        backup_last = None
        if len(backups) != 0:
            backup_last = backups[-1]
            treepath_last = backup_last.get_treepath()

        # If --lock specified, only one receiver at a time.
        # This temp file will get deleted before the script ends,
        # unless the power cord is pulled. On Linux and Macs, /tmp
        # gets cleared at boot, so backup will be unlocked. On
        # Windows, there isn't an equivalent. Also note flock
        # doesn't work in some filesystems such as nfs.
        # For these reasons, locking is optional.

        if have_option('--lock'):
            lock_file = LockFile('lockfile.lb')
            if not lock_file.lock():
                results = 'Attempt to lock failed.'
                send_object(-1)
                send_object(results)
                send_object(None)
                return results, None

        # Command?

        if have_option('--showfiles'):
            showfiles = catalog.get_showfiles(filelist, treepath_last)
            results = '\n'.join([filelist[n][0] for n in showfiles])
            subdir = None
        else:
            # Calc when the server should stop; used for --minutes control

            end_time = 0
            for n in xrange(len(sys.argv)):
                if sys.argv[n] == '--minutes':
                    end_time = int(time.time()) + int(sys.argv[n + 1]) * 60
                    break

            # Update catalog

            complete, transferred, md5hashes = catalog.update(filelist, treepath_last, end_time)
            if complete:
                results = 'catalog update complete, %d bytes transferred.' % transferred
            else:
                results = 'catalog update not complete. %d bytes transferred.' % transferred

            # Count stats

            verbose_log('catalog stats:')
            new = 0
            copy = 0
            for entry in catalog.parse_log(catalog.get_logfiles()[-1][1]):
                if entry[0] == 'copy':
                    copy += 1
                elif entry[0] == 'new':
                    new += 1
            results += '\ncatalog: %d new %d copied.' % (new, copy)

            # Create structure if complete
            # Don't create if --catalogonly specified
            # Don't create if new tree would be identical to old tree

            subdir = None
            if complete and not have_option('--catalogonly') and not is_tree_equal(filelist, treepath_last):
                backup_new = manager.new_backup()
                backup_new.build_tree(backup_last, filelist, md5hashes, catalog)
                subdir = backup_new.get_treepath()
                results += '\ntree created: %s' % subdir

                # 'latest' link
                latest_link = join(manager.get_path(), 'latest')
                if os.path.exists(latest_link):
                    os.remove(latest_link)
                os.symlink(backup_new.get_dirname(), join(manager.get_path(), 'latest'))

                # tree stats

                new = 0
                copy = 0
                link = 0
                for entry in backup_new.parse_log():
                    if entry[0] == 'copy':
                        copy += 1
                    elif entry[0] == 'new':
                        new += 1
                    elif entry[0] == 'link':
                        link += 1
                results += '\ntree: %d new %d copied %d linked.' % (new, copy, link)
            else:
                results += '\ntree not created.'

        # Send results

        send_object(results)
        send_object(subdir)

    return results, subdir

def parse_address(string):
    """Parse these formats:
    dir
    user@host:dir

    Return dictionary:
    remote : user@host or empty
    path : path portion
    string : whole string
    """

    addr = {}
    addr['string'] = string
    if string.find(':') != -1:
        addr['remote'], addr['path'] = string.split(':')
    else:
        addr['remote'] = ''
        addr['path'] = string
        
    # Check to see if we are in quotes
    # Unicode might be an issue here..
    addr['path'] = shlex.split(addr['path'])[0]
    
    return addr

def have_option(option):
    for s in sys.argv:
        if s == option:
            return True
    return False

def get_option_value(option):
    for n in xrange(len(sys.argv)):
        if sys.argv[n] == option:
            return sys.argv[n + 1]
    return None

def error(string):
    sys.stderr.write("*** " + string + "\n")
    sys.exit(1)

class LockFile:
    def __init__(self, file_name):
        # /tmp gets cleared at system boot on *nix systems,
        # so the file will get cleared if the system reboots.
        # On Windows all bets are off.
        self.file_name = join(tempfile.gettempdir(), file_name)
        self.file = None

    def lock(self):
        # Fail if locked twice. No need to reference count
        if self.file:
            return False

        # Attempt an exclusive, non-blocking lock
        # Doesn't work on NFS
        self.file = file(self.file_name, 'w+')
        try:
            fcntl.flock(self.file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except IOError, e:
            self.file.close()
            self.file = None
            return False
        return True

    def unlock(self):
        if self.file:
            self.file.close()
            self.file = None
            os.unlink(self.file_name)

    def __del__(self):
        # Gets called if script is control-c'd
        self.unlock()

# Main code

if __name__ == '__main__':
    # Print help

    if len(sys.argv) == 1:
        print __doc__
        sys.exit(1)

    if len(sys.argv) < 3:
        error('Too few parameters.')

    # Parse addresses

    src = parse_address(sys.argv[-2:-1][0])
    dst = parse_address(sys.argv[-1:][0])

    if have_option('--ssh-i') or have_option('--ssh-C') or have_option('--ssh-p'):
        error("--ssh-x style options have been deprecated in favor of -e (rsync style). Please change your command.")

    # Is this the server?

    if have_option('--server'):
        init_io(sys.stdout, sys.stdin)
        execute(src, dst, have_option('--source'))
        sys.exit(0)

    # Client starting. Only one remote allowed.

    if src['remote'] and dst['remote']:
        error('Source and Dest cannot both be remote.')
        
    # The source generates the file list, the dest asks for new files
    # The server can talk through stderr to the console

    if not src['remote']:
        # Client is source, server is dest
        
        start_server(src, dst, False)
        results, subdir = execute(src, dst, True)

    else:
        # Server is source, client is dest

        start_server(src, dst, True)
        results, subdir = execute(src, dst, False)

    # Print results

    print results

    # Verification

    if subdir != None:
        srcpath = '%s/' % os.path.normpath(src['path'])
        if (src['remote']):
            srcpath = src['remote'] + ':' + repr(srcpath)
        dstpath = os.path.normpath(join(dst['path'], subdir))
        if (dst['remote']):
            dstpath = dst['remote'] + ':' + repr(dstpath)
        if os.getuid() == 0 and have_option('--numeric-ids'):
            rsync_cmd = 'rsync -av --numeric-ids --dry-run %s %s' % (dump_arg(srcpath), dump_arg(dstpath))
        else:
            rsync_cmd = 'rsync -av --dry-run %s %s' % (dump_arg(srcpath), dump_arg(dstpath))

        if have_option('--verify'):
            print rsync_cmd
            sys.stdout.flush()
            os.system(rsync_cmd)
        else:
            print 'to cross-verify:'
            print rsync_cmd

    # Close server

    fd_send.close()
    fd_recv.close()
    sys.exit(0)
