
require 'logger'
require 'fileutils'

$logger = Logger.new "remote-client.log"

LSYNC_TMP_DIRECTORY = "/tmp/lsync-#{Process.pid}"
FileUtils.mkdir_p(LSYNC_TMP_DIRECTORY)
FileUtils.chmod 0700, LSYNC_TMP_DIRECTORY

def script_path(named)
  File.join(LSYNC_TMP_DIRECTORY, "#{name}")
end

module RemoteMethods
  def self.create_script(name, code)
    path = script_path(name)
    
    File.open(path, "w") do |f|
      f.write(code)
    end
    
    FileUtils.chmod 0755, path
    
    $scripts[name] = path
  end
  
  def self.run_script(name, *args)
    system($scripts[name], *args)
  end
end

begin
  $connection.run do |message|
    method = message.shift
    $logger.info("Calling #{method}...")
    result = RemoteMethods.send(method, *message)
  
    conn.send(result)
  end
rescue
  $logger.error("Exception caught: #{$!}")
  exit(1)
ensure
  FileUtils.rm_rf(LSYNC_TMP_DIRECTORY)
end
