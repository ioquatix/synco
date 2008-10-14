
# A backup script coordinates "one" backup as a unit.

require 'lsync/action'
require 'lsync/method'

module LSync
  
  class BackupError
    
    def initialize(reason, server, error)
      @reason = reason
      @server = server
      @error = error
    end
    
    def to_s
      @reason
    end
    
  end
  
  module RunActions
    def run_actions(actions)
      actions = @actions[actions] if actions.class == Symbol
      actions.each { |a| a.run_on_server(self) }
    end
  end
  
  class Directory
    def initialize(config)
      @path = config["path"]
      @user = config["user"]
    end
    
    def to_s
      @path
    end
    
    def user
      @user
    end
    
    include RunActions
  end
  
  class Server
    def initialize(config)
      @host = config["host"]
      @root = config["root"]
      
      @actions = {
        :pre => (config["pre"] || []).collect { |c| Action.new(c) },
        :post => (config["post"] || []).collect { |c| Action.new(c) }
      }
      
      @user = config["user"]
      
      @enabled = true
    end
    
    def full_path(directory)
			# Directories need to have trailing slashes
      return File.expand_path(directory.to_s, @root || "/") + "/"
    end
    
    def host_location
      @user ? "#{@user}@#{@host}" : @host
    end
    
    def connection_string(directory)
      if is_local?
        return full_path(directory)
      else
        return host_location + ":" + full_path(directory).dump
      end
    end
    
    def is_local?
      return true if @host == "localhost"
      
      hostname = Socket.gethostname
      
      begin
        hostname = Socket.gethostbyname(hostname)[0]
      rescue SocketError
        puts $!
      end
      
      return @host == hostname
    end
    
    def to_s
        "#{host_location}:#{@root}"
    end
    
    def should_run?
      return @enabled
    end
    
    def host
      @host
    end
    
    def ssh_options
      {}
    end
    
    def user
      @user
    end
    
    include RunActions
  end
  
  class BackupScript
  private
    def find_master_server(name)
      if @servers.key? name
        return @servers[name]
      else
        hostname = Socket.gethostbyname(name)[0] rescue name
        return @servers.values.find { |s| s["host"] == hostname }
      end
    end
    
    def find_current_server
      @servers.values.find { |s| s.is_local? }
    end
    
  public
    def initialize(config)
      @servers = config.keys_matching(/^server\./) { |c| Server.new(c) }
      @directories = config.keys_matching(/^directory\./) { |c| Directory.new(c) }
      
      @master = find_master_server(config["master"])
      abort "Could not determine master server" if @master == nil
      
      @method = Method.new(config["method"])
    end

		attr :master
		attr :method
		attr :servers
		attr :directories
    
    def run_backup
      # Find out if the master server is local...
      if @master.is_local?
        puts "We are the master server..."
        current = @master
      else
        puts "We are not the master server..."
        puts "Master server is #{@master}..."
        # Find a server config that specifies the local host
        current = find_current_server
      end
      
      abort "Can't determine current server" if current == nil
      
      # Run server pre-scripts.. if these fail then we abort the backup
      begin
        current.run_actions(:pre)
      rescue
        throw BackupError.new("Server #{current} pre-actions failed...", current, $!)
      end
      
      puts "Running backups for server #{current}..."
      
      begin
        @servers.each do |name, s|
          # S is always a data destination, therefore s can't be @master
          next if s == @master
          
          # Skip servers that shouldn't be processed
          unless @method.should_run?(@master, current, s)
            puts "\tSkipping        : #{s}"
            next
          end
          
          begin
            s.run_actions(:pre)
          rescue
            $stderr.puts "Server #{s} pre-actions failed..."
            $stderr.puts $!
            $stderr.puts "...aborting backups for this server!"
            next
          end
          
          @directories.each do |name, d|
            puts "\tProcessing #{d} : #{s}"
            @method.run(@master, s, d)
          end
      
          begin
            s.run_actions(:post)
          rescue
            throw BackupError.new("Server #{current} post-actions failed...", s, $!)
          end
        end
      ensure
        # We must run post scripts even if there were major problems running the actual backups
        # Post-scripts might fail, but we can't do anything about it if they do except
        # report it to the user
        begin
          current.run_actions(:post)
        rescue
          throw BackupError.new("Server #{current} post-actions failed...", current, $!)
        end
      end
    end
    
    def self.load_from_file(path)
      new(YAML::load(File.read(path)))
    end
  end
  
end