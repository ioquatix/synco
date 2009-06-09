
require 'lsync/shell'

module LSync
  
  class Server
    def initialize(config)
      @host = config["host"] || "localhost"
      @root = config["root"] || "/"

      @actions = {
        :before => (config["before"] || []).collect { |c| Action.new(c) },
        :after => (config["after"] || []).collect { |c| Action.new(c) }
      }

      @shell = Shell.new(config["shell"])

      @enabled = true
      
      @connection = nil
      @pid = nil
    end

    def full_path(directory = "./")
      # Directories need to have trailing slashes
      return File.expand_path(directory.to_s, backup_path) + "/"
    end

    def connection_string(directory)
      if is_local?
        return full_path(directory)
      else
        return @host + ":" + full_path(directory).dump
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
      "#{@host}:#{full_path}"
    end

    def should_run?
      return @enabled
    end

    def connect
      unless @connection
        puts "Opening shell: #{@shell.full_path(self)}..."
        @connection, @pid = @shell.connect(self)
      end
      
      return @connection
    end

    attr :host
    attr :shell
    attr :root
    
    def root_path
      if @root == nil
        return "/"
      elsif @root.kind_of? Array
        return @root[0]
      else
        return @root.to_s
      end
    end
    
    def backup_path
      if @root == nil
        return "/"
      elsif @root.kind_of? Array
        return File.join(@root)
      else
        return @root.to_s
      end
    end

    def run_actions(actions, logger)
      actions = @actions[actions] if actions.class == Symbol
      return if actions.size == 0
      
      logger.info "Running #{actions.size} action(s):"
      
      actions.each do |a|
        begin
          a.run_on_server(self, logger)
        rescue StandardError
          raise BackupActionError.new(self, a, $!)
        end
      end
    end
  end
end
