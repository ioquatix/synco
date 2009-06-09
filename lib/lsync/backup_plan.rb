
# A backup plan is a rule-based engine to process individual scripts.
# Failure and success can be delt with over multiple scripts.

require 'ruleby'

module Ruleby
  def self.engine(name, &block)
    e = Core::Engine.new
    yield e if block_given?
    return e
  end
end

module LSync

  BuiltInCommands = {
    "ping-host" => "ping -c 4 -t 5 -o"
  }

  module Facts
    class Initial
    end

    class StageSucceeded
      def initialize(stage)
        @stage = stage
        puts "Stage Succeeded: #{@stage.name}"
      end

      attr :stage

      def name
        @stage.name
      end
    end

    class StageFailed
      def initialize(stage)
        @stage = stage
      end

      attr :stage

      def name
        @stage.name
      end
    end

    class ScriptSucceeded
      def initialize(stage, script)
        @stage = stage
        @script = script
      end

      attr :stage
      attr :script
    end

    class ScriptFailed
      def initialize(stage, script)
        @stage = stage
        @script = script
      end

      attr :stage
      attr :script
    end
  end

  class BackupPlanRulebook < Ruleby::Rulebook
    include Facts

    def rules
      #rule [ScriptSucceeded, :m] do |v|
      #	script = v[:m].script
      #  puts "Backup #{script.dump} successful"
      #end

      rule [ScriptFailed, :m] do |v|
        script = v[:m].script
        puts "*** Script #{script} failed"
      end

      #rule [StageSucceeded, :m] do |v|
      #	stage = v[:m].stage
      #  puts "Stage #{stage.name.dump} successful"
      #end
    end
  end

  class StageRulebook < Ruleby::Rulebook
    include Facts

    def initialize(engine, stage)
      super(engine)
      @stage = stage
    end

    def rules
      # Does this stage have any rules? (i.e. can it run in any case?)
      if @stage.rules.size > 0
        puts "Loading rules for stage #{@stage.name.dump}..."
        @stage.rules.each do |name, r|
          puts "\t#{name}..."

          r["when"].each do |s|
            puts "\t\t#{s.dump}"
          end

          options = r.dup
          wh = options.delete("when")

          # Build rule
          rule("#{@stage.name}_#{name}".to_sym, options, *wh) do |v|
            @stage.run_scripts
          end
        end
      end
    end

    # Bring names into the right scope (i.e. Facts)
    def __eval__(x)
      eval(x)
    end
  end

  class Stage
    protected
    RuleConfigKeys = Set.new(["priority", "when"])

    def process_rules config			
      rules = config.keys_matching(/^rule\.(.*)$/)

      if rules.size > 0
        # Okay
      elsif config.key? "when"
        rules = {
          "rule.default" => config.delete_if { |k,v| !RuleConfigKeys.include?(k) }
        }
      else
        return {}
      end

      rules.keys.each do |rule_name|
        options = {}
        w = rules[rule_name].delete("when") || []
        w = [w] if w.is_a? String

        rules[rule_name].each { |k,v| options[k.to_sym] = v }
        rules[rule_name] = options
        rules[rule_name]["when"] = w.collect { |s| s.gsub('@', '#') }
      end

      rules
    end

    def process_scripts config
      config["scripts"].collect do |s|
        s.match(/^([^\s]+)(.*)$/)

        if BuiltInCommands.key? $1
          BuiltInCommands[$1] + $2
        else
          s
        end
      end
    end

    public
    def initialize(plan, name, config)
      @plan = plan
      @name = name

      @scripts = process_scripts(config)
      @rules = process_rules(config)
    end

    def run_scripts
      failed = false

      puts "Running stage #{@name}..."
      @scripts.each do |script|
        puts "\tRunning Script #{script}..."

        if system(script)
          @plan.engine.assert Facts::ScriptSucceeded.new(self, script)
        else
          @plan.engine.assert Facts::ScriptFailed.new(self, script)
          failed = true
        end
      end

      if failed
        @plan.engine.assert Facts::StageFailed.new(self)
      else
        @plan.engine.assert Facts::StageSucceeded.new(self)
      end
    end

    attr :name
    attr :scripts
    attr :rules
  end

  class BackupPlan
    def initialize(config, logger = nil)
      @logger = logger || Logger.new(STDOUT)
      
      @config = config.keys_matching(/^scripts\.(.*)$/)
      @stages = config.keys_matching(/^stage\.(.*)$/) { |c,name| Stage.new(self, name, c) }
    end

    attr :logger, true
    attr :config

    def run_backup
      Ruleby.engine :engine do |e|
        @engine = e

        puts " Loading Rules ".center(80, "=")

        BackupPlanRulebook.new(e).rules

        @stages.each do |k,s|
          StageRulebook.new(e, s).rules
        end

        puts " Processing Rules ".center(80, "=")

        e.assert Facts::Initial.new

        e.match
        @engine = nil
      end

      puts " Finished ".center(80, "=")
    end

    attr :engine
    attr :config
    attr :stages

    def self.load_from_file(path)
      new(YAML::load(File.read(path)))
    end
  end

end