
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
      else
        @command = "ssh $HOST $RUBY"
        @options = {}
      end
      
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
            args += ['-o', "User #{v.to_s}".dump]
          end
        end
      end
      
      return args.join(" ")
    end
    
    def ruby_path
      @options["ruby"] || "ruby"
    end
    
    def full_command(server, include_ruby = false)
      remote_path = @command + " " + command_options
      remote_path.gsub!("$HOST", server.host)
      remote_path.gsub!("$ROOT", server.root_path)
      
      return remote_path
    end
    
    # Return a connection object representing a connection to the given server.
    def connect(server)
      if server.is_local?
        return RExec::start_server(CLIENT_CODE, ruby_path, :passthrough => [])
      else
        return RExec::start_server(CLIENT_CODE, full_command(server, true), :passthrough => [], :ruby => ruby_path)
      end
    end
    
    attr :command
    attr :name
  end
  
end
