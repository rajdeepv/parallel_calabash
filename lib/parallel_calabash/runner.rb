module ParallelCalabash
  class Runner
    class << self
      def base_command
        'calabash-android run'
      end

      def run_tests(test_files, process_number, options)
        cmd = [base_command, options[:apk_path], options[:cucumber_options], *test_files].compact*' '
        execute_command_for_process(process_number, cmd, options[:mute_output])
      end

      def execute_command_for_process(process_number, cmd, silence)
        command_for_current_process = command_for_process(process_number, cmd)
        output = open("|#{command_for_current_process}", "r") { |output| show_output(output, silence) }
        exitstatus = $?.exitstatus

        if silence
          $stdout.print output
          $stdout.flush
        end
        puts "\n****** PROCESS #{process_number} COMPLETED ******\n\n"
        {:stdout => output, :exit_status => exitstatus}
      end

      def command_for_process process_number, cmd
        env = {}
        device_for_current_process = ParallelCalabash::AdbHelper.device_for_process process_number
        env = env.merge({'AUTOTEST' => '1', 'ADB_DEVICE_ARG' => device_for_current_process, "TEST_PROCESS_NUMBER" => (process_number+1).to_s})
        separator = (WINDOWS ? ' & ' : ';')
        exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}=#{v};export #{k}" }.join(separator)
        exports + separator + cmd
      end

      def show_output(output, silence)
        result = ""
        loop do
          begin
            read = output.readpartial(1000000) # read whatever chunk we can get
            result << read
            unless silence
              $stdout.print read
              $stdout.flush
            end
          end
        end rescue EOFError
        result
      end

    end
  end
end