
require 'lsync/to_cmd'

module LSync
  
  class Method
    @@methods = {}
    
    def self.register(name, handler)
      @@methods[name] = handler
    end
    
    def self.lookup(name)
      @@methods[name]
    end
    
    def initialize(config)
      @name, @options = config.split(/\s+/, 2)
      
      @method = Method.lookup(@name)
      abort "Could not find method #{@name}" if @method == nil
    end
    
    def run(master_server, target_server, directory)
      @method.run(master_server, target_server, directory, @options)
    end
    
    def should_run?(master_server, current_server, target_server)
      @method.should_run?(master_server, current_server, target_server)
    end
  end
  
  module Methods
    module DirectionalMethodHelper
      def initialize(direction)
        @direction = direction
      end
    
      def run(master_server, target_server, directory, options)
        if @direction == :push
          src = master_server.full_path(directory)
          dst = target_server.connection_string(directory)
        else
          src = master_server.connection_string(directory)
          dst = target_server.full_path(directory)
        end
      
        run_handler(src, dst, options)
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
    end
  
    class RSync
      include DirectionalMethodHelper
    
      def run_handler(src, dst, options)
        puts "rsync #{options} #{src.dump} #{dst.dump}"
        system("rsync #{options} #{src.dump} #{dst.dump}")
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
        puts "python #{LinkBackup.lb_bin.dump} #{options} #{src.dump} #{dst.dump}"
        system("python #{LinkBackup.lb_bin.dump} #{options} #{src.dump} #{dst.dump}")
      end
    end
  
    Method.register("lb-pull", LinkBackup.new(:pull))
    Method.register("lb-push", LinkBackup.new(:push))
  
  end
  
end
