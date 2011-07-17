
module LSync

	# Base exception class which keeps track of related components.
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

	# Indicates that there has been a major backup script error.
	class ScriptError < Error
	end

	# Indicates that there has been a major backup method error.
	class BackupMethodError < Error
	end

	# Indicates that a backup action shell script has failed.
	class ShellScriptError < Error
		def initialize(script, return_code)
			super("Shell script #{script} failed", :return_code => return_code)
		end
	end
end