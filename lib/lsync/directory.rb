
require 'pathname'

class Pathname
  def components
    return to_s.split(SEPARATOR_PAT)
  end
end

module LSync
  
  class Directory
    def initialize(config)
      @path = Pathname.new(config["path"]).cleanpath
      
      abort "Directory paths must be relative (#{config["path"]} is absolute!)." if @path.absolute?
    end
    
    attr :path
    
    def to_s
      @path.to_s
    end
  end
  
end