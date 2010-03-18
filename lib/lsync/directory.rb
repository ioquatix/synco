
require 'pathname'

class Pathname
  def components
    return to_s.split(SEPARATOR_PAT)
  end
  
  def normalize_trailing_slash
    if to_s.match(/\/$/)
      return self
    else
      return self.class.new(to_s + "/")
    end
  end
end

module LSync
  
  class Directory
    def initialize(config)
      @path = Pathname.new(config["path"]).cleanpath.normalize_trailing_slash
      
      abort "Directory paths must be relative (#{config["path"]} is absolute!)." if @path.absolute?
    end
    
    attr :path
    
    def to_s
      @path.to_s
    end
    
    # Special exception for root path
    def depth
      return @path.to_s.scan("/").size - 1
    end
  end
  
end