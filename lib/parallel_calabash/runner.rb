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
      $stdout.print "#{process_number}>> Command: #{test}\n"
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
          options[:simulator] || '0-0')
      $stdout.print "#{process_number}>> Command: #{test}\n"
      $stdout.flush


      o = execute_command_for_process(process_number, test)
      device = @device_helper.device_for_process process_number
      log = "/tmp/PCal-#{device[:user]}.process_number"
      puts "Writing log #{log}"
      open(log, 'w') { |file| file.print o[:stdout] }
      o
    end

    def command_for_test(process_number, test_files, app_path, cucumber_options, simulator)
      device = @device_helper.device_for_process process_number
      separator = (WINDOWS ? ' & ' : ';')
      remote = device[:user] ? "ssh #{device[:user]}@localhost" : 'bash -c'

      if device[:calabash_server_port]
        user_app = copy_app_set_port(app_path, device)
      else
        user_app = app_path
      end

      device_name = device[:device_name] || "par-cal-#{device[:user]}"
      device_simulator = device[:simulator] || simulator
      device_target = device[:device_target] || "#{device_name} (#{version(device_simulator)} Simulator)"
      device_info = device[:device_info] || (device[:user] ? create_simulator(device_name, remote, simulator) : '')
      device_endpoint = device[:device_endpoint] || "http://localhost:#{device[:calabash_server_port]}"
      $stdout.print "#{process_number}>> Device: #{device_info} = #{device_name} = #{device_target}\n"
      $stdout.flush

      cmd = [base_command, "APP_BUNDLE_PATH=#{user_app}", cucumber_options, *test_files].compact*' '

      env = {
          AUTOTEST: '1',
          DEVICE_ENDPOINT: device_endpoint,
          DEVICE_TARGET: device_target,
          DEVICE_INFO: device_info,
          TEST_USER: device[:user] || %x( whoami ).strip,
          # 'DEBUG_UNIX_CALLS' => '1',
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: "pc_#{process_number+1}_"
      }
      env['BUNDLE_ID'] = ENV['BUNDLE_ID'] if ENV['BUNDLE_ID']
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}='#{v}';export #{k}" }.join(separator)

      cmd = [ exports,  "#{device[:init] || ' : '}", "cd #{File.absolute_path('.')}", "umask 002", cmd].join(separator)

      if device[:user]
        "#{remote} bash -lc \"#{cmd}\" 2>&1"
      else
        "bash -c \"#{cmd}\" 2>&1"
      end
    end

    def udid(name)
      name = name.gsub(/(\W)/, '\\\\\\1')
      line = %x( instruments -s devices ).split("\n").grep(/#{name}/)
      fail "Found #{line.size} matches for #{name}, expected 1" unless line.size == 1
      line.first.match(/\[(\S+)\]/).captures.first.to_s
    end

    def version(simulator)
      simulator.match('\d+-\d+$').to_s.gsub('-', '.')
    end

    def prepare_for_parallel_execution
      # copy-chown all the files, and set everything group-writable.
      Find.find('.') do |path|
        if File.file?(path) && !File.stat(path).owned?
          temp = "#{path}......"
          FileUtils.copy(path, temp)
          FileUtils.move(temp, path)
          puts "Chowned/copied.... #{path}"
        end
      end
      FileUtils.chmod_R('g+w', 'build/reports')
      FileUtils.chmod('g+w', Dir['*'])
      FileUtils.chmod('g+w', '.')
    end

    def create_simulator(device_name, ssh, simulator)
      stop_and_remove(device_name, ssh)
      puts "Double check..."
      stop_and_remove(device_name, ssh)
      puts "OK if none"

      device_info = %x( #{ssh} "xcrun simctl create #{device_name} #{simulator}" ).strip
      fail "Failed to create #{device_name} for #{ssh}" unless device_info
      device_info
    end

    def stop_and_remove(device_name, ssh)
      devices = %x( #{ssh} "xcrun simctl list devices" | grep #{device_name} )
      puts "Devices: #{devices}"
      devices.each_line do |device|
        _name, id, state = device.match(/^\s*([^(]*?)\s*\((\S+)\)\s+\((\S+)\)/).captures
        puts 'Shutdown: ' + %x( #{ssh} "xcrun simctl shutdown #{id}" ) if state =~ /booted/
        puts 'Delete: ' + %x( #{ssh} "xcrun simctl delete #{id}" )
      end
    end

    def copy_app_set_port(app_path, device)
      user_path = File.dirname(app_path) + '/' + device[:user]
      FileUtils.rmtree(user_path)
      FileUtils.mkdir_p(user_path)
      user_app = user_path + '/' + File.basename(app_path)
      FileUtils.copy_entry(app_path, user_app)

      # Set plist.

      unless system("/usr/libexec/PlistBuddy -c 'Add CalabashServerPort integer #{device[:calabash_server_port]}' #{user_app}/Info.plist")
        raise 'Unable to set CalabashServerPort'
      end

      puts "User app: #{user_app}"

      user_app
    end
  end
end