require 'fileutils'

module ParallelCalabash
  module DevicesHelper
    def device_for_process process_num
      connected_devices_with_model_info[process_num]
    end

    def number_of_connected_devices
      connected_devices_with_model_info.size
    end
  end

  class AdbHelper
    include ParallelCalabash::DevicesHelper

    def initialize(filter = [])
      @filter = filter
    end

    def connected_devices_with_model_info
      begin
        list =
            `adb devices -l`.split("\n").collect do |line|
              device = device_id_and_model(line)
              filter_device(device)
            end
        list.compact
      rescue
        []
      end
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

  class IosHelper
    include ParallelCalabash::DevicesHelper

    def initialize(filter = nil, default_simulator = nil, config_file = nil, instruments = nil)
      @filter = filter || []
      @default_simulator = default_simulator || {}
      config_file = config_file || "#{ENV['HOME']}/.parallel_calabash"
      if config_file.is_a? Hash
          @config = config_file
        else
          @config = File.exist?(config_file) ? eval(File.read(config_file)) : {}
      end
      @instruments = instruments || %x(instruments -s devices)
    end

    def connected_devices_with_model_info
      return @devices if @devices
      if @config[:DEVICES]
        configs = apply_filter(compute_devices)
        fail '** No devices (or users) unfiltered!' if configs.empty?
      else
        configs = apply_filter(compute_simulators)
        configs = configs.empty? ? [@default_simulator] : configs
      end
      @devices = configs
    end

    def compute_simulators
      port = (@config[:CALABASH_SERVER_PORT] || 28000).to_i
      users = @config[:USERS] || []
      init = @config[:INIT] || ''
      users.map.with_index do |u, i|
        {USER: u, CALABASH_SERVER_PORT: port + i, INIT: init}
      end
    end

    def compute_devices
      users = @config[:USERS] || []
      init = @config[:INIT] || ''
      devices = remove_unconnected_devices(@config[:DEVICES])
      fail 'Devices configured, but no devices attached!' if devices.empty?
      configs = devices.map.with_index do |d, i|
        if users[i]
          d[:USER] = users[i]
          d[:INIT] = init
          d
        else
          print "** No user for device #{d}"
          nil
        end
      end
      configs.compact
    end

    def apply_filter(configs)
      return configs if @filter.empty?
      filter_join = @filter.join('|')
      configs.select do |c|
        [c.keys, c.values].flatten.find { |k| k.to_s.match(filter_join) }
      end
    end

    def remove_unconnected_devices(configs)
      udids = @instruments.each_line.map { |n| n.match(/\[(.*)\]/) && $1 }.flatten.compact
      configs.find_all do |c|
        var = c[:DEVICE_TARGET]
        !udids.grep(var).empty?
      end
    end
  end
end
