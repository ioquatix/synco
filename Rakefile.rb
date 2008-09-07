require "lib/lsync"

task :backup do
  
  config = LSync::Config.load_from_file(ENV["conf"] || "test.conf")
  
  config.run_backup
  
end