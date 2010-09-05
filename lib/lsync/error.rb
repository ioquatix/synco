
module LSync
  
  class Error < StandardError
    def initialize(reason, components = {})
      @reason = reason
      @components = components
    end
    
    def to_s
      @reason
    end
    
    attr :reason
    attr :components
  end
  
  class ScriptError < BackupError
  end
  
  class BackupMethodError < BackupError
  end
  
  class ConfigurationError < BackupError
  end
  
  class BackupActionError < BackupError
    def initialize(server, action, exception)
      super("Backup action failed: #{action} (#{exception.to_s})", :action => action, :exception => exception)
    end
  end
  
end