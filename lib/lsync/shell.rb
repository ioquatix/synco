
require 'rexec'
require 'pathname'

module LSync
  CLIENT_CODE = (Pathname.new(__FILE__).dirname + "shell_client.rb").read
  
  class Shell
    # Command can be something like "ssh -l username -p 110"
    def initialize(config)
      if config.kind_of? String
        @command = config
        @options = {}
      elsif config.kind_of? Hash
        @command = config["command"]
        @options = config.dup
      end
      
      @command ||= "ssh $OPTIONS $HOST"
      @options ||= {}
      
      if @command.match(/([^\s]+)/)
        @name = $1
      else
        @name = nil
      end
    end
    
    def command_options
      args = []
      
      if @name == "ssh"
        @options.each do |k,v|
          case(k.to_sym)
          when :port
            args += ['-p', v.to_i]
          when :key
            args += ['-i', v.dump]
          when :keys
            v.each { |key_path| args += ['-i', key_path.dump] } 
          when :timeout
            args += ['-o', "ConnectTimeout #{v.to_i}".dump]
          when :compression
            args += ['-C']
          when :user
            args += ['-l', v.to_s.dump]
            # args += ['-o', "User #{v.to_s}".dump]
          end
        end
      end
      
      return args.join(" ")
    end
    
    def ruby_path
      @options["ruby"] || "ruby"
    end
    
    def full_command(server = nil)
      cmd = @command.dup
      
      cmd.gsub!("$OPTIONS", command_options)

      if server
        cmd.gsub!("$HOST", server.host)
        cmd.gsub!("$ROOT", server.root_path)
      end
      
      return cmd
    end
    
    protected
    # Return a connection object representing a connection to the given server.
    def open_connection(server)
      if server.is_local?
        $stderr.puts "Opening connection to #{ruby_path.dump}"
        return RExec::start_server(CLIENT_CODE, ruby_path, :passthrough => [])
      else
        $stderr.puts "Opening connection to #{full_command(server).dump}"
        return RExec::start_server(CLIENT_CODE, full_command(server), :passthrough => [], :ruby => ruby_path)
      end
    end
    
    public
    def connect(server)
      connection, pid = open_connection(server)
      message = connection.receive
      
      abort "Remote shell connection was not successful: #{message}" unless message == :ready
      
      return connection, pid
    end
    
    attr :command
    attr :name
  end
  
end
