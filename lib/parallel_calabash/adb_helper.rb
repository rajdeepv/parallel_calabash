module ParallelCalabash
  module AdbHelper
    class << self

      def device_for_process process_num, filter=[]
        connected_devices_with_model_info(filter)[process_num]
      end

      def number_of_connected_devices filter=[]
        connected_devices_with_model_info(filter).size
      end

      def connected_devices_with_model_info filter
        begin
          list =
            `adb devices -l`.split("\n").collect do |line|
              device = device_id_and_model(line)
              filter_device(device, filter)
            end
          list.compact
        rescue
          []
        end
      end

      def device_id_and_model line
        if line.include?("device ")
          [line.split(" ").first,line.scan(/model:(.*) device/).flatten.first]
        end
      end

      def filter_device device, filter
        if filter && !filter.empty? && device
          device unless filter.collect{|f| device[0].match(f) || device[1].match(f) }.compact.empty?
        else
          device
        end
      end

    end

  end
end