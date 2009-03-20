#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'digest'

LOG_FILE = "backup-test.log"

class BackupTest < Test::Unit::TestCase
  def setup
    @src = "BackupTestSrc"
    @dst = "BackupTestDst"
    
    FileUtils.rm_rf @src
    FileUtils.rm_rf @dst
    
    FileUtils.mkdir @src
    FileUtils.mkdir @dst
    
    (1...10).each do |i|
      p = File.join(@src, i.to_s)
      
      FileUtils.mkdir(p)
      
      dg = Digest::MD5.hexdigest(i.to_s)
      fn = i.to_s
      
      File.open(File.join(p, fn), "w") { |f| f.write(dg) }
    end
  end
  
  def teardown
    FileUtils.rm_rf @src
    FileUtils.rm_rf @dst
  end
  
  def test_script
    system("lsync", "local.conf")
  end
end