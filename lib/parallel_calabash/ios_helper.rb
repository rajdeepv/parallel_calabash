require 'parallel_calabash/device_helper'
module ParallelCalabash
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
      @instruments = instruments || %x(instruments -s devices ; echo) # Bizarre workaround for xcode 7
    end

    def connected_devices_with_model_info
      return @devices if @devices
      if @config[:DEVICES]
        configs = apply_filter(compute_devices)
        fail '** No devices unfiltered!' if configs.empty?
      else
        configs = apply_filter(compute_simulators)
        configs = configs.empty? ? [@default_simulator] : configs
      end
      @devices = configs
    end

    def compute_simulators
      port = (@config[:CALABASH_SERVER_PORT] || 28000).to_i
      no_of_devices = @config[:NO_OF_DEVICES].to_i || 1
      simulator = @config[:DEVICE_TARGET] || nil
      (1..no_of_devices).map do |i|
        {}.tap do |my_hash|
          my_hash[:DEVICE_TYPE] = simulator unless simulator.nil?
          my_hash[:DEVICE_TARGET] = "PCalSimulator_#{i}"
          my_hash[:CALABASH_SERVER_PORT] = port + i - 1
        end
      end
    end

    def compute_devices
      port = (@config[:CALABASH_SERVER_PORT] || 28000).to_i
      devices = remove_unconnected_devices(@config[:DEVICES])
      fail 'Devices configured, but no devices attached!' if devices.empty?
      configs = devices.map.with_index do |d, i|
        d[:CALABASH_SERVER_PORT] = port + i
        d[:DEVICE] = true
        d
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