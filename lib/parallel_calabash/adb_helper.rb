module ParallelCalabash
  module AdbHelper
    class << self

      def connected_devices
        begin
          `adb devices`.scan(/\n(.*)\t/).flatten
        rescue
          []
        end
      end

      def device_for_process process_num
        connected_devices[process_num]
      end

      def number_of_connected_devices
        connected_devices.size
      end

    end

  end
end