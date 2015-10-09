require 'parallel_calabash/base_runner'

module ParallelCalabash 
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
          options[:simulator] || '0-0', options[:device_endpoint])
      $stdout.print "#{process_number}>> Command: #{test}\n"
      $stdout.flush

      o = execute_command_for_process(process_number, test)
      device = @device_helper.device_for_process process_number
      log = "/tmp/PCal-#{process_number+1}.process_number"
      puts "Writing log #{log}"
      open(log, 'w') { |file| file.print o[:stdout] }
      o
    end

    def command_for_test(process_number, test_files, app_path, cucumber_options, simulator, endpoint)
      device = @device_helper.device_for_process process_number
      separator = (WINDOWS ? ' & ' : ';')

      device_simulator = device[:DEVICE_TYPE] || simulator
      device_name = device[:DEVICE_TARGET] || "PCalSimulator_#{process_number+1}"

      if device[:CALABASH_SERVER_PORT]
        process_app = copy_app_set_port(app_path, device, "PCal_app_#{process_number}")
      else
        process_app = app_path
      end
      
      # Device target changed in XCode 7, losing ' Simulator' for some reason.
      device_target = device[:DEVICE] ? device_name : create_simulator(device_name, "#{device_simulator}", )
      device_endpoint = device_endpoint || "http://localhost:#{device[:CALABASH_SERVER_PORT]}"
      $stdout.print "#{process_number}>> Device: #{device_target} = #{device_name}\n"
      $stdout.flush

      unless @skip_ios_ping_check
        hostname = device_endpoint.match("http://(.*):").captures.first
        pingable = system "ping -c 1 -o #{hostname}"
        fail "Cannot ping device_endpoint host: #{hostname}" unless pingable
      end
      initializer_cmd = "open -n `xcode-select -p`/Applications/iOS\\ Simulator.app --args -CurrentDeviceUDID #{device_target}"
      install_cmd = "xcrun simctl install '#{device_target}' '#{process_app}'"
      cmd = [base_command, "APP_BUNDLE_PATH=#{process_app}", cucumber_options, *test_files].compact*' '

      env = {
          AUTOTEST: '1',
          DEVICE_ENDPOINT: device_endpoint,
          DEVICE_TARGET: device_target,
          DEVICE_INFO: device_name,
          # 'DEBUG_UNIX_CALLS' => '1',
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: "PCal_#{process_number+1}_",
          NO_LAUNCH: '1'
      }
      env['BUNDLE_ID'] = ENV['BUNDLE_ID'] if ENV['BUNDLE_ID']
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}='#{v}';export #{k}" }.join(separator)

      cmd = [ exports, initializer_cmd, install_cmd, "cd #{File.absolute_path('.')}", "umask 002", cmd].join(separator)

      "bash -c \"#{cmd}\" 2>&1"
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

    def create_simulator(device_name, simulator)
      stop_and_remove(device_name)
      puts "Double check..."
      stop_and_remove(device_name)
      puts "OK if none"

      device_info = %x( xcrun simctl create "#{device_name}" #{simulator} ).strip
      fail "Failed to create #{device_name} for #{simulator}" unless device_info
      device_info
    end

    def stop_and_remove(device_name)
      devices = %x( xcrun simctl list devices | grep "#{device_name}" )
      puts "Devices: #{devices}"
      devices.each_line do |device|
        _name, id, state = device.match(/^\s*([^(]*?)\s*\((\S+)\)\s+\((\S+)\)/).captures
        puts 'Shutdown: ' + %x( xcrun simctl shutdown #{id}) if state =~ /booted/
        puts 'Delete: ' + %x( xcrun simctl delete #{id})
      end
    end

    def copy_app_set_port(app_path, device, target_path)
      process_path = File.dirname(app_path) + '/' + target_path
      FileUtils.rmtree(process_path)
      FileUtils.mkdir_p(process_path)
      process_app = process_path + '/' + File.basename(app_path)
      FileUtils.copy_entry(app_path, process_app)

      # Set plist.

      system("/usr/libexec/PlistBuddy -c 'Delete CalabashServerPort integer #{device[:CALABASH_SERVER_PORT]}' #{process_app}/Info.plist")
      unless system("/usr/libexec/PlistBuddy -c 'Add CalabashServerPort integer #{device[:CALABASH_SERVER_PORT]}' #{process_app}/Info.plist")
        raise "Unable to set CalabashServerPort in #{process_app}/Info.plist"
      end

      puts "Process app: #{process_app}"

      process_app
    end
  end
end