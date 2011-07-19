LSync
=====

* Author: Samuel G. D. Williams (<http://www.oriontransfer.co.nz>)
* Copyright (C) 2009, 2011 Samuel G. D. Williams.
* Released under the MIT license.

LSync is a tool for scripted synchronization and backups. It provides a custom Ruby
DSL for describing complex backup and synchronization tasks. It is designed to give
maximum flexibility while reducing the complexity of describing complex multi-server
setups.

* Single and multi-server data synchronization.
* Incremental backups both locally and remotely.
* Backup staging and coordination.
* Backup verification using `Fingerprint`.
* Data backup redundancy controlled via DNS.

For examples please see the main [project page][1].

[1]: http://www.oriontransfer.co.nz/gems/lsync

License
-------

Copyright (c) 2009, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>

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