
require 'termios'

module Password
	def self.echo(on=true, masked=false)
		term = Termios::getattr( $stdin )

		if on
			term.c_lflag |= ( Termios::ECHO | Termios::ICANON )
		else # off
			term.c_lflag &= ~Termios::ECHO
			term.c_lflag &= ~Termios::ICANON if masked
		end

		Termios::setattr( $stdin, Termios::TCSANOW, term )
	end

	def self.get(message="Password: ")
		begin
			if $stdin.tty?
				echo false
				print message if message
			end

			pw = $stdin.gets
			pw.chomp!
		ensure
			if $stdin.tty?
				echo true
				print "\n"
			end
		end
	end
end

