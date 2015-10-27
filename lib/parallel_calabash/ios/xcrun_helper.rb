require 'run_loop'

module ParallelCalabash
  module Ios
    class XcrunHelper
      def self.sim_name
        run_loop = RunLoop::SimControl.new
        if run_loop.xcode_version_gte_7?
          'Simulator'
        elsif run_loop.xcode_version_gte_6?
          'iOS Simulator'
        else
          'iPhone Simulator'
        end
      end

      def self.stop_and_remove(device_name, ssh)
        devices = %x( #{ssh} "xcrun simctl list devices | grep \"#{device_name}\"" )
        puts "Devices: #{devices}"
        devices.each_line do |device|
          _name, id, state = device.match(/^\s*([^(]*?)\s*\((\S+)\)\s+\((\S+)\)/).captures
          self.try_stop_simulator id, state, ssh
          puts 'Delete: ' + %x( #{ssh} "xcrun simctl delete #{id}")
        end
      end

      def self.try_stop_simulator device_uuid, state, ssh
        if state.downcase =~ /booted/
          %x( #{ssh} "xcrun simctl shutdown #{device_uuid}")
          pids = %x( #{ssh} "ps -e | grep #{device_uuid}")
          if pids.match(self.sim_name)
            app_pid = pids.lines.select {|line| line.match self.sim_name }.first.split(" ").first
            %x(#{ssh} "kill -9 #{app_pid}")
            puts "Shutdown: #{device_uuid}"
          else
            puts "Shutdown: #{device_uuid} failed, not present"
          end
        end
      end

      def self.create_simulator(device_name, ssh, simulator)
        stop_and_remove(device_name, ssh)
        device_info = %x( #{ssh} "xcrun simctl create '#{device_name}' #{simulator}" ).strip
        fail "Failed to create #{device_name} for #{simulator}" unless device_info
        device_info
      end

      def initialize env, is_device, device_target
        @env = env
        @is_device = is_device
        @simulator_uuid = !@is_device ? device_target : nil
      end

      def start_simulator_and_app_if_needed
        unless @is_device
          %x( xcrun simctl boot '#{@simulator_uuid}' )
          %x( xcrun simctl install '#{@simulator_uuid}' '#{@env[:APP_BUNDLE_PATH]}' )
          %x( xcrun simctl shutdown '#{@simulator_uuid}' )
          %x( xcrun open -n -g -a "#{XcrunHelper.sim_name}" --args -CurrentDeviceUDID #{@simulator_uuid} )
          %x( mkdir -p ./.run-loop/#{@simulator_uuid} )
          launch_app
        end
      end

      def launch_app
        %x( instruments -w '#{@simulator_uuid}' \
            -D './.run-loop/#{@simulator_uuid}/instrument.trace' \
            -t Automation '#{@env[:APP_BUNDLE_PATH]}' \
            -e UIASCRIPT '#{File.join(File.dirname(__FILE__),"../../../misc/startup_popup_close.js")}' \
            -e UIARESULTSPATH ./.run-loop/#{@simulator_uuid} \
            >& ./.run-loop/#{@simulator_uuid}/run-loop.out )
      end

      def set_env_vars_if_needed
        unless @is_device
          @env[:DEVICE_TARGET] = device_instruments_target(@simulator_uuid)
          @env[:SIMULATOR_UUID] = @simulator_uuid
        end
        @env[:NO_LAUNCH] = '1'
      end

      private
      def device_instruments_target device_target
        device = %x( instruments -s devices | grep "#{device_target}" )
        _name, platform, uuid = device.match(/([A-z0-9_]*)\s([(].*[)])\s(.*)/).captures
        "#{_name} #{platform}"
      end
    end
  end
end