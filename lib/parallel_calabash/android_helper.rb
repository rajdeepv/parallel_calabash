require 'parallel_calabash/device_helper'

module ParallelCalabash
  class AdbHelper
    include ParallelCalabash::DevicesHelper

    def initialize(filter = [])
      @filter = filter
    end

    def adb_devices_l
      `adb devices -l`
    end

    def connected_devices_with_model_info
      begin
        list =
            adb_devices_l.split("\n").collect do |line|
              device = device_id_and_model(line)
              filter_device(device)
            end
        list.compact.each { |device_data| device_data << screenshot_prefix(device_data.first) }
      rescue
        []
      end
    end

    def screenshot_prefix device_id
      device_id.gsub('.', '_').gsub(/:(.*)/, '').to_s + '_'
    end

    def device_id_and_model line
      if line.match(/device(?!s)/)
        [line.split(" ").first, line.scan(/model:(.*) device/).flatten.first]
      end
    end

    def filter_device device
      if @filter && !@filter.empty? && device
        device unless @filter.collect { |f| device[0].match(f) || device[1].match(f) }.compact.empty?
      else
        device
      end
    end
  end
end
