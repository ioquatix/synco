
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
      def ssh_options_string(server)
        args = []
        
        server.ssh_options.each do |k,v|
          case(k.to_sym)
          when :port
            args += ['-p', v.to_i]
          when :keys
            v = [v] unless v.is_a? Array
            v.each { |i| args += ['-i', i.dump] } 
          when :timeout
            args += ['-o', "ConnectTimeout #{v.to_i}".dump]
          when :compression
            args += ['-C']
          when :user
            args += ['-o', "User #{v.to_s}".dump]
          end
        end
        
        return args.join(" ")
      end
      
      def connect_options_for_server (local_server, remote_server)
        '-e' + ' ' + ('ssh ' + ssh_options_string(remote_server)).dump
      end
      
      public
      def initialize(direction)
        @direction = direction
      end
    
      def run(master_server, target_server, directory, options, logger)
        options ||= ""
        
        if @direction == :push
          src = master_server.full_path(directory)
          dst = target_server.connection_string(directory)
          options += " " + connect_options_for_server(master_server, target_server)
        else
          src = master_server.connection_string(directory)
          dst = target_server.full_path(directory)
          options += " " + connect_options_for_server(target_server, master_server)
        end
        
        @logger = logger
        
        if run_handler(src, dst, options) == false
          raise BackupMethodError.new("Backup from #{src.dump} to #{dst.dump} failed.", :method => self)
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
        @logger.info "Running command: #{cmd}..."
        
        process_result = IO.open_process(cmd) do |pin, pout, perr, pid|
          pin.close
          pipes = [pout, perr]

          while pipes.size > 0
            result = IO.select(pipes)

            result[0].each do |pipe|
              if pipe.closed? || pipe.eof?
                pipes.delete(pipe)
                next
              end

              if pipe == pout
                @logger.info pipe.readline.chomp
              elsif pipe == perr
                @logger.error pipe.readline.chomp
              end
            end
          end
          
        end
        
        process_result.exitstatus == 0
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
