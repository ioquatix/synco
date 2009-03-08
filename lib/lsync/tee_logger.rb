
module TeeHelper
  def tee(*loggers)
    return TeeLogger.new(self, *loggers)
  end
end

class TeeLogger
  def initialize(*loggers)
    @loggers = Set.new(loggers.flatten.compact)
  end

  attr :loggers

  def self.logger_methods
    Set.new(Logger.instance_methods) - Set.new(Object.instance_methods + %w(tee))
  end

  logger_methods.each do |method|
    define_method(method) do |*args|
      @loggers.each { |l| l.send(method, *args) }
    end
  end
  
  include TeeHelper
end

class Logger
  include TeeHelper
end

class MinimalLogFormat
  def call(severity, time, progname, msg)
    "[#{severity.rjust(8)}] #{msg}\n"
  end
end

