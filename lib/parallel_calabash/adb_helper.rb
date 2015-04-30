module ParallelCalabash
  module AdbHelper
    class << self

      def device_for_process process_num
        connected_devices_with_model_info[process_num]
      end

      def number_of_connected_devices
        connected_devices_with_model_info.size
      end

      def connected_devices_with_model_info
        begin
          `adb devices -l`.split("\n").collect{|line|  device_id_and_model(line)}.compact
        rescue
          []
        end
      end

      def device_id_and_model line
        if line.match(/device(?!s)/)
          [line.split(" ").first,line.scan(/model:(.*) device/).flatten.first]
        end
      end

    end

  end
end
