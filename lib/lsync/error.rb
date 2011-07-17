
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

	class ScriptError < Error
	end

	class BackupMethodError < Error
	end

	class ConfigurationError < Error
	end

	# If a backup action fails, this error may be raised.
	class ShellScriptError < Error
		def initialize(script, return_code)
			super("Shell script #{script} failed", :return_code => return_code)
		end
	end
end