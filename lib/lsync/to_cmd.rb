
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

class IO
  RD = 0
  WR = 1
  
  def self.open_process(cmd)
    cin = IO.pipe
    cout = IO.pipe
    cerr = IO.pipe
    
    cid = fork do
      cin[WR].close
      cout[RD].close
      cerr[RD].close
      
      STDIN.reopen(cin[RD])
      STDOUT.reopen(cout[WR])
      STDERR.reopen(cerr[WR])
      
      STDOUT.sync=(true) if not STDOUT.sync
      STDERR.sync=(true) if not STDERR.sync
      
      exec(cmd)
    end
    
    cin[RD].close
    cout[WR].close
    cerr[WR].close
    
    yield cin[WR], cout[RD], cerr[RD]
    
    Process.wait(cid)
    
    return $?
  end
end
