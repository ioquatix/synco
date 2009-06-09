
module LSync
  
  class Directory
    def initialize(config)
      @path = config["path"]
      @user = config["user"]
      
      @method = config["method"]
    end

    def to_s
      @path
    end

    attr :user
    attr :method
  end
  
end