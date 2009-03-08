# Copyright (c) 2007 Samuel Williams. Released under the GNU GPLv2.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'

gem 'termios'
gem 'net-ssh'
gem 'ruleby'

require 'yaml'
require 'socket'
require 'set'
require 'logger'

require 'lsync/version'
require 'lsync/extensions'
require 'lsync/backup-script'
require 'lsync/backup-plan'
require 'lsync/tee_logger'

require 'fileutils'
require 'optparse'

require 'open-uri'

module LSync
  
  class BackupError < Exception
    def initialize(reason, components = {})
      @reason = reason
      @components = components
    end
    
    def to_s
      @reason
    end
    
    attr :reason
    attr :components
  end
  
  class BackupScriptError < BackupError
  end
  
  class BackupMethodError < BackupError
  end
  
  class ConfigurationError < BackupError
  end
  
  class BackupActionError < BackupError
    def initialize(server, action, exception)
      super("Backup action failed: #{action}", :action => action, :exception => exception)
    end
  end
  
end