
class String
  def to_cmd
    (match(/\s/) ? dump : self) 
  end
end

class Array
  def to_cmd
    collect{|a| a.to_cmd }.join(" ")
  end
end
