require 'parallel_calabash/base_runner'
require 'parallel_calabash/ios/xcrun_helper'
require 'run_loop'

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

      device_simulator_type = device[:DEVICE_TYPE] || simulator
      device_name = device[:DEVICE_TARGET]

      if device[:CALABASH_SERVER_PORT]
        process_app = copy_app_set_port(app_path, device, "PCal_app_#{process_number}")
      else
        process_app = app_path
      end
      
      device_target = device[:DEVICE] ? device_name : ParallelCalabash::Ios::XcrunHelper.create_simulator(device_name, "#{device_simulator_type}" )
      device_endpoint = endpoint || "http://localhost:#{device[:CALABASH_SERVER_PORT]}"
      $stdout.print "#{process_number}>> Device: #{device_target} = #{device_name}\n"
      $stdout.flush
      
      unless @skip_ios_ping_check
        hostname = device_endpoint.match("http://(.*):").captures.first
        pingable = system "ping -c 1 -o #{hostname}"
        fail "Cannot ping device_endpoint host: #{hostname}" unless pingable
      end

      env = {
          AUTOTEST: '1',
          DEVICE_ENDPOINT: device_endpoint,
          DEVICE_TARGET: device_target,
          # 'DEBUG_UNIX_CALLS' => '1',
          TEST_PROCESS_NUMBER: (process_number+1).to_s,
          SCREENSHOT_PATH: "PCal_#{process_number+1}_",
          APP_BUNDLE_PATH: process_app
      }
      
      xcrun_helper = ParallelCalabash::Ios::XcrunHelper.new(env, device[:DEVICE], device_target)
      xcrun_helper.set_env_vars_if_needed
      xcrun_helper.start_simulator_and_app_if_needed

      cmd = [base_command, cucumber_options, *test_files].compact*' '

      env['BUNDLE_ID'] = ENV['BUNDLE_ID'] if ENV['BUNDLE_ID']
      exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}='#{v}';export #{k}" }.join(separator)

      cmd = [ exports, "cd #{File.absolute_path('.')}", "umask 002", cmd].join(separator)

      "bash -c \"#{cmd}\" 2>&1"
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