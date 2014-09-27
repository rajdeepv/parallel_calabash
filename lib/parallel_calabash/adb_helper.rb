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
    end

  end
end