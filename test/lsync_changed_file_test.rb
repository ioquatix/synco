#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'digest'

LOG_FILE = "backup-test.log"

class BackupTest < Test::Unit::TestCase
  def setup
    @src = "BackupTestSrc"
    @dst = "BackupTestDst"
    @junk = File.join(@src, 'junk')
    
    FileUtils.rm_rf @src
    FileUtils.rm_rf @dst
    
    FileUtils.mkdir @src
    FileUtils.mkdir @dst
    
    # Make a file 256Mbytes big
    puts "Generating junk..."
    system("dd", "if=/dev/zero", "of=#{@junk}", "count=256", "bs=#{1024*1024}")
    puts "Done!"
  end
  
  def teardown
    #FileUtils.rm_rf @src
    #FileUtils.rm_rf @dst
  end
  
  def test_script
    Thread.new do
      sleep(4)
      puts "****** Messing with file... ******"
      File.open(@junk, "a") { |f| f.write("Hello World!") }
    end
    
    system("lsync", "local.conf")
  end
end