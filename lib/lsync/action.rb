
require 'pathname'
require 'lsync/run'
require 'lsync/backup_error'

module LSync
  
  class AbortBackupException < Exception
    
  end
  
  class Action
    def initialize(function)
      @function = function
      
      if @function.match(/^\%([a-z]+)(\s+.*)?$/)
        @script_name = $1
        @arguments = $2
      else
        @script_name = nil
      end
    end
    
    def to_s
      @function
    end
    
    def run_on_server(server, logger)
      logger.info "Running #{@function} on #{server}"
      
      if server.is_local?
        run_locally(server, logger)
      else
        run_remotely(server, logger)
      end
    end
    
  private
    def run_locally(server, logger)
      command = nil
      
      if @script_name
        uname = `uname`.chomp.downcase
        
        local_path = Action.script_path(uname, @script_name)
        command = local_path.to_cmd + @arguments
      else
        command = @function
      end
      
      ret = nil
      Dir.chdir(server.root_path) do
        ret = LSync.run_command(command, logger)
      end
      
      case(ret)
      when 0
        return
      when 1
        raise AbortBackupException
      else
        raise BackupActionError
      end
    end
    
    def run_remotely(server, logger)
      remote_shell.connect do |shell|
        command = nil
        
        if @script_name
          uname = shell.verbose_exec!("uname").chomp.downcase

          local_path = Action.script_path(uname, script_name)
          command = local_path.to_cmd + arguments
        else
          command = @function
        end

        return shell.execute_script_remotely(parts.to_cmd)
      end
    end
    
    def self.script_path(platform, name)
      exact_script_path(platform, name) || exact_script_path("generic", name)
    end
    
    private
    def self.exact_script_path(platform, name)
      path = (Pathname.new(__FILE__).dirname + "actions" + platform + name).expand_path
      path.exist? ? path : nil
    end
  end

end