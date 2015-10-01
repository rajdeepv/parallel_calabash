require 'parallel_calabash/base_runner'

module ParallelCalabash
  class AndroidRunner
    include Runner

    def initialize(device_helper, silence)
      @device_helper = device_helper
      @silence = silence
    end

    def prepare_for_parallel_execution
      # Android is fairly sane....
    end

    def base_command
      'calabash-android run'
    end

    def run_tests(test_files, process_number, options)
      cmd = command_for_test(
          process_number, base_command, options[:apk_path],
          "#{options[:cucumber_options]} #{options[:cucumber_reports]}", test_files)
      $stdout.print "#{process_number}>> Command: #{cmd}\n"
      $stdout.flush
      execute_command_for_process(process_number, cmd)
    end

    def command_for_test(process_number, base_command, apk_path, cucumber_options, test_files)
      cmd = [base_command, apk_path, cucumber_options, *test_files].compact*' '
      device_id, device_info = @device_helper.device_for_process process_number
      env = {
          AUTOTEST: '1',
          ADB_DEVICE_ARG: device_id,
          DEVICE_INFO: device_info,
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: device_id.to_s + '_'
      }
      separator = (WINDOWS ? ' & ' : ';')
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}=#{v};export #{k}" }.join(separator)
      exports + separator + cmd
    end
  end
end
