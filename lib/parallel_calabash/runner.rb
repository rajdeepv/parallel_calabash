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
      execute_command_for_process(process_number, cmd)
    end

    def command_for_test(process_number, base_command, apk_path, cucumber_options, test_files)
      cmd = [base_command, apk_path, cucumber_options, *test_files].compact*' '
      device_id, device_info = @device_helper.device_for_process process_number
      env = {
          'AUTOTEST' => '1',
          'ADB_DEVICE_ARG' => device_id,
          'DEVICE_INFO' => device_info,
          'TEST_PROCESS_NUMBER' => (process_number+1).to_s
      }
      separator = (WINDOWS ? ' & ' : ';')
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}=#{v};export #{k}" }.join(separator)
      exports + separator + cmd
    end
  end

  class IosRunner
    include Runner

    def initialize(device_helper, silence)
      @device_helper = device_helper
      @silence = silence
    end

    def base_command
      'bundle exec cucumber'
    end

    def run_tests(test_files, process_number, options)
      test = command_for_test(
          process_number, test_files,
          options[:app_path], "#{options[:cucumber_options]} #{options[:cucumber_reports]}",
          options[:simulator])
      puts "#{process_number}>> Command: #{test}"
      execute_command_for_process(process_number, test)
    end

    def command_for_test(process_number, test_files, app_path, cucumber_options, simulator)
      device = @device_helper.device_for_process process_number
      separator = (WINDOWS ? ' & ' : ';')
      remote = "#{device[:user]}@localhost"

      user_app = copy_app_set_port(app_path, device)

      version = simulator.match('\d+-\d+$').to_s.gsub('-', '.')
      device_name = device['deviceName'] || "par-cal-#{device[:user]}"
      device_info = create_simulator(device_name, remote, simulator)
      device_target = "#{device_name} (#{version} Simulator)"
      puts "#{process_number}>> Simulator: #{device_info} = #{device_name} = #{device_target}"

      cmd = [base_command, "APP_BUNDLE_PATH=#{user_app}", cucumber_options, *test_files].compact*' '

      env = {
          'AUTOTEST' => '1',
          'DEVICE_ENDPOINT' => "http://localhost:#{device['CalabashServerPort']}",
          'DEVICE_TARGET' => device_target,
          'DEVICE_INFO' => device_info,
          'TEST_USER' => device[:user],
          'TEST_PROCESS_NUMBER' => (process_number+1).to_s
      }
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}='#{v}';export #{k}" }.join(separator)

      cmd = [ exports,  "#{device['init'] || ''}", "cd #{File.absolute_path('.')}", "umask 002", cmd].join(separator)

      "ssh #{remote} bash -lc \"#{cmd}\" 2>&1"
    end

    def prepare_for_parallel_execution
      Find.find('.') do |path|
        if File.file?(path) && !File.stat(path).owned?
          temp = "#{path}......"
          FileUtils.copy(path, temp)
          FileUtils.move(temp, path)
          puts "Acquired.... #{path}"
        end
      end
      FileUtils.chmod_R('g+w', 'build/reports')
      FileUtils.chmod('g+w', Dir['*'])
    end

    def create_simulator(device_name, remote, simulator)
      stop_and_remove(device_name, remote)
      puts "Double check..."
      stop_and_remove(device_name, remote)
      puts "OK if none"

      device_info = %x( ssh #{remote} "xcrun simctl create #{device_name} #{simulator}" ).strip
      fail "Failed to create #{device_name} for #{remote}" unless device_info
      device_info
    end

    def stop_and_remove(device_name, remote)
      devices = %x( ssh #{remote} "xcrun simctl list devices" | grep #{device_name} )
      puts "Devices: #{devices}"
      devices.each_line do |device|
        _name, id, state = device.match(/^\s*([^(]*?)\s*\((\S+)\)\s+\((\S+)\)/).captures
        puts 'Shutdown: ' + %x( ssh #{remote} "xcrun simctl shutdown #{id}" ) if state =~ /booted/
        puts 'Delete: ' + %x( ssh #{remote} "xcrun simctl delete #{id}" )
      end
    end

    def copy_app_set_port(app_path, device)
      user_path = File.dirname(app_path) + '/' + device[:user]
      FileUtils.rmtree(user_path)
      FileUtils.mkdir_p(user_path)
      user_app = user_path + '/' + File.basename(app_path)
      FileUtils.copy_entry(app_path, user_app)

      # Set plist.

      unless system("/usr/libexec/PlistBuddy -c 'Add CalabashServerPort integer #{device['CalabashServerPort']}' #{user_app}/Info.plist")
        raise 'Unable to set CalabashServerPort'
      end

      puts "User app: #{user_app}"

      user_app
    end
  end
end