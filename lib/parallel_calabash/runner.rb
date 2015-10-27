require 'fileutils'
require 'find'
require 'parallel_calabash/ios/xcrun_helper'
require 'run_loop'

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
      $stdout.print "#{process_number}>> Command: #{cmd}\n"
      $stdout.flush
      execute_command_for_process(process_number, cmd)
    end

    def command_for_test(process_number, base_command, apk_path, cucumber_options, test_files)
      cmd = [base_command, apk_path, cucumber_options, *test_files].compact*' '
      device_id, device_info, screenshot_prefix = @device_helper.device_for_process process_number
      env = {
          AUTOTEST: '1',
          ADB_DEVICE_ARG: device_id,
          DEVICE_INFO: device_info,
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: screenshot_prefix
      }
      separator = (WINDOWS ? ' & ' : ';')
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}=#{v};export #{k}" }.join(separator)
      exports + separator + cmd
    end
  end

  class IosRunner
    include Runner

    def initialize(device_helper, silence, skip_ios_ping_check)
      @device_helper = device_helper
      @silence = silence
      @skip_ios_ping_check = skip_ios_ping_check
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
      log = "/tmp/PCal-#{device[:USER]}.#{process_number}"
      puts "Writing log #{log}"
      open(log, 'w') { |file| file.print o[:stdout] }
      o
    end

    def command_for_test(process_number, test_files, app_path, cucumber_options, simulator)
      device = @device_helper.device_for_process process_number
      separator = (WINDOWS ? ' & ' : ';')
      remote = device[:USER] ? "ssh #{device[:USER]}@localhost" : 'bash -c'

      if device[:CALABASH_SERVER_PORT]
        user_app = copy_app_set_port(app_path, device, device[:USER] || "PCal_app_#{process_number}")
      else
        user_app = app_path
      end

      device_name = device[:DEVICE_NAME] || "PCal-#{device[:USER]}"
      device_simulator = device[:SIMULATOR] || simulator

      device_target = device[:DEVICE_TARGET] || ParallelCalabash::Ios::XcrunHelper.create_simulator(device_name, remote, "#{device_simulator}" )
      device_endpoint = device[:DEVICE_ENDPOINT] || "http://localhost:#{device[:CALABASH_SERVER_PORT]}"
      $stdout.print "#{process_number}>> Device: #{device_name} = #{device_target}\n"
      $stdout.flush

      unless @skip_ios_ping_check
        hostname = device_endpoint.match("http://(.*):").captures.first
        pingable = system "ping -c 1 -o #{hostname}"
        fail "Cannot ping device_endpoint host: #{hostname}" unless pingable
      end

      cmd = [base_command, "APP_BUNDLE_PATH=#{user_app}", cucumber_options, *test_files].compact*' '

      env = {
          AUTOTEST: '1',
          DEVICE_ENDPOINT: device_endpoint,
          DEVICE_TARGET: device_target,
          TEST_USER: device[:USER] || %x( whoami ).strip,
          # 'DEBUG_UNIX_CALLS' => '1',
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: "PCal_#{process_number+1}_",
          APP_BUNDLE_PATH: user_app
      }

      unless device[:USER]
        xcrun_helper = ParallelCalabash::Ios::XcrunHelper.new(env, device[:DEVICE], device_target)
        xcrun_helper.set_env_vars_if_needed
        xcrun_helper.start_simulator_and_app_if_needed
      end
      
      env['BUNDLE_ID'] = ENV['BUNDLE_ID'] if ENV['BUNDLE_ID']
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}='#{v}';export #{k}" }.join(separator)

      cmd = [ exports,  "#{device[:INIT] || ' : '}", "cd #{File.absolute_path('.')}", "umask 002", cmd].join(separator)

      if device[:USER]
        "#{remote} bash -lc \"#{cmd}\" 2>&1"
      else
        "bash -c \"#{cmd}\" 2>&1"
      end
    end

    # def udid(name)
    #   name = name.gsub(/(\W)/, '\\\\\\1')
    #   line = %x( instruments -s devices ).split("\n").grep(/#{name}/)
    #   fail "Found #{line.size} matches for #{name}, expected 1" unless line.size == 1
    #   line.first.match(/\[(\S+)\]/).captures.first.to_s
    # end

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
      FileUtils.chmod_R('g+w', 'build/reports') if File.exists? 'build/reports'
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

    def copy_app_set_port(app_path, device, target_path)
      process_path = File.dirname(app_path) + '/' + target_path
      FileUtils.rmtree(process_path)
      FileUtils.mkdir_p(process_path)
      process_app = process_path + '/' + File.basename(app_path)
      FileUtils.copy_entry(app_path, process_app)

      RunLoop::PlistBuddy.new.plist_set("CalabashServerPort", "integer", device[:CALABASH_SERVER_PORT], "#{process_app}/Info.plist")

      puts "Process app: #{process_app}"

      process_app
    end
  end
end
