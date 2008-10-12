require 'rubygems'
require 'rake/gempackagetask'
require 'lib/lsync/version'

spec = Gem::Specification.new do |s| 
  s.name = "LSync"
  s.version = LSync::VERSION::STRING
  s.author = "Samuel Williams"
  s.email = "samuel.williams@oriontransfer.co.nz"
  s.homepage = "http://wiki.oriontransfer.org/?lsync"
  s.platform = Gem::Platform::RUBY
  s.summary = "LSync is a tool for creating and managing a CA for use with Radmind"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.executables << 'lsync'
#  s.autorequire = "name"
#  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
#  s.extra_rdoc_files = ["README"]
  s.add_dependency("termios")
  s.add_dependency("net-ssh")
  s.add_dependency("ruleby")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end
