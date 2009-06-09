
require 'fileutils'
require 'lsync/run'

module LSync
  
  class Method
    @@methods = {}
    
    def self.register(name, handler)
      @@methods[name] = handler
    end
    
    def self.lookup(name)
      @@methods[name]
    end
    
    def initialize(config, logger = nil)
      @logger = logger || Logger.new(STDOUT)
      
      @name, @options = config.split(/\s+/, 2)
      
      @method = Method.lookup(@name)
      
      if @method == nil
        raise BackupError.new("Could not find method #{@name}!")
      end
    end
    
    attr :logger, true
    
    def run(master_server, target_server, directory)
      @method.run(master_server, target_server, directory, @options, @logger)
    end
    
    def should_run?(master_server, current_server, target_server)
      @method.should_run?(master_server, current_server, target_server)
    end
  end
  
  module Methods
    module DirectionalMethodHelper
      protected
      def connect_options_for_server (local_server, remote_server)
        ['-e', remote_server.shell.full_command(remote_server).dump].join(" ")
      end
      
      public
      def initialize(direction)
        @direction = direction
      end
    
      def run(master_server, target_server, directory, options, logger)
        options ||= ""
        options += " " + directory.method
        
        local_server = nil
        remote_server = nil
        
        if @direction == :push
          local_server = master_server
          remote_server = target_server
          
          dst = remote_server.connection_string(directory)
          src = local_server.full_path(directory)
        else
          local_server = target_server
          remote_server = master_server
          
          src = remote_server.connection_string(directory)
          dst = local_server.full_path(directory)
        end
        
        options += " " + connect_options_for_server(local_server, remote_server)
        FileUtils.mkdir_p(local_server.full_path(directory))
        
        @logger = logger
        
        Dir.chdir(local_server.root_path) do
          if run_handler(src, dst, options) == false
            raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
          end
        end
      end
    
      def should_run?(master_server, current_server, target_server)
        if @direction == :push
          return current_server == master_server
        elsif @direction == :pull
          return target_server.is_local?
        else
          return false
        end
      end
      
      def run_command(cmd)
        return LSync.run_command(cmd, @logger) == 0
      end
    end
  
    class RSync
      include DirectionalMethodHelper
    
      def run_handler(src, dst, options)
        run_command("rsync #{options} #{src.dump} #{dst.dump}")
      end
    end
  
    Method.register("rsync-pull", RSync.new(:pull))
    Method.register("rsync-push", RSync.new(:push))
  
    class LinkBackup
      include DirectionalMethodHelper
      
      def self.lb_bin
        return File.join(File.dirname(__FILE__), "lb.py")
      end
      
      def run_handler(src, dst, options)
        
        
        # Verbose mode for debugging..
        # options += " --verbose"
        run_command("python #{LinkBackup.lb_bin.dump} #{options} #{src.dump} #{dst.dump}")
      end
    end
  
    Method.register("lb-pull", LinkBackup.new(:pull))
    Method.register("lb-push", LinkBackup.new(:push))
  
  end
  
end
