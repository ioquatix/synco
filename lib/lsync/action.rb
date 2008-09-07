
require 'net/ssh'
require 'lsync/to_cmd'

class Net::SSH::Connection::Session
  def verbose_exec!(command, &block)
    block ||= Proc.new do |ch, stream, data|
      if stream == :stderr
        $stderr.write(data) 
      else
        ch[:result] ||= ""
        ch[:result] << data
      end
    end

    puts "SSH: #{command}"
    channel = exec(command, &block)
    channel.wait

    return channel[:result]
  end
end

module LSync
  
  class Action
    def initialize(function)
      @function = function
      
      if @function.match(/\%([a-z]+)/)
        @script_name = $1
      else
        @script_name = nil
      end
    end
    
    def run_on_server(server)
      puts "Running #{@function} on #{server}"
      
      return
      
      if server.is_localhost?
        run_locally(server.user)
      else
        run_remotely(server.host, server.user, server.ssh_options)
      end
    end
    
  private
    def run_locally(user)
      command = nil
      
      if @script_name
        uname = `uname`.chomp.downcase
        
        local_path = Action.script_path(uname, script_name)
        command = local_path.to_cmd + arguments
      else
        command = @function
      end
      
      IO.popen(command) do |io|
        result = io.read
      end
      
      return result
    end
    
    def run_remotely(host, user, options = {})
      Net::SSH.start(host, user, options) do |ssh|
        command = nil
        
        if @script_name
          uname = ssh.verbose_exec!("uname").chomp.downcase

          local_path = Action.script_path(uname, script_name)
          command = local_path.to_cmd + arguments
        else
          command = @function
        end
        
        # Create a temporary location for the script
        remote_path = ssh.verbose_exec!("mktemp -t #{File.basename(local_path)}.XXXX").chomp
        
        ssh.sftp.upload(local_path, remote_path)
        ssh.verbose_exec!("chmod +x #{remote_path}")
        
        parts = command
        result = ssh.verbose_exec!(parts.to_cmd)
      end
      
      return result
    end
    
    def self.script_path(platform, name)
      File.join(File.dirname(__FILE__), platform, name)
    end
  end

end