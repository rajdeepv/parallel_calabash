require 'fileutils'
require 'find'

module ParallelCalabash
  module Runner
    def execute_command_for_process(process_number, cmd)
      output = open("|#{cmd}", 'r') { |output| show_output(output, process_number) }
      exitstatus = $?.exitstatus

      if @silence
        $stdout.print output
        $stdout.flush
      end
      puts "\n****** PROCESS #{process_number} COMPLETED ******\n\n"
      {:stdout => output, :exit_status => exitstatus}
    end

    def show_output(output, process_number)
      result = ''
      loop do
        begin
          unless @silence
            read = output.readline()
            $stdout.print "#{process_number}> #{read}"
            $stdout.flush
          else
            read = output.readpartial(1000000) # read whatever chunk we can get
          end
          result << read
        end
      end rescue EOFError
      result
    end
  end
end