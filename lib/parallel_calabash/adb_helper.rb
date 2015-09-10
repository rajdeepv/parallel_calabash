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

    def initialize(filter = nil, default_device = nil, user_glob = '/Users/*/.parallel_calabash*')
      @filter = filter || []
      @default_device = default_device || {}
      @user_glob = user_glob
    end

    def connected_devices_with_model_info
      return @devices if @devices
      puser_dirs = Dir.glob(@user_glob).select { |d| d.match(/\/.?[^.~]+(\.\d+)?$/) }
      configs = puser_dirs.collect { |file_name| read_config_file(file_name) }.compact
      configs.sort_by!{|p| p[:ORDER] || p[:USER] || p[:DEVICE_INFO] || p[:CALABASH_SERVER_PORT]}
      configs = @filter.empty? ? configs : configs.select do |c|
        c.keys.find{ |k| k.to_s.match(@filter.join('|')) } ||
            c.values.find{ |k| k.to_s.match(@filter.join('|'))  }
      end
      configs = filter_unconnected_devices(configs)
      assert_unique_simulator_ports(configs)
      @devices = configs.empty? ? [@default_device] : configs
    end

    def filter_unconnected_devices(configs)
      udids =  %x(instruments -s devices).each_line.map{|n| n.match(/\[(.*)\]/) && $1}.flatten.compact
      configs.find_all {|c| !c[:DEVICE_TARGET] || !udids.grep(c[:DEVICE_TARGET]).empty?}
    end

    def assert_unique_simulator_ports(configs)
      configs.inject({}) do |h, c|
        p = c[:CALABASH_SERVER_PORT]
        next h unless p
        fail_on_port_clash(h, p.to_i, c)
      end
    end

    def fail_on_port_clash(h, p, c)
      fail "CALABASH_SERVER_PORT=#{p} already used by #{h[p]}" if h[p]
      h[p] = c
      h
    end

    def read_config_file(file_name)
      user = File.basename(File.dirname(file_name))
      config = File.open(file_name) { |file| read_config(file, user) }
      if config.has_key?(:CALABASH_SERVER_PORT) || config.has_key?(:DEVICE_ENDPOINT)
        config
      else
        puts "User #{user} must define either 'CALABASH_SERVER_PORT' or 'DEVICE_ENDPOINT' in #{config}"
        nil
      end
    end

    def read_config(file, user)
      file.readlines.grep(/^\s*[^#]/).inject({USER: user}) do |h, l|
        p = l.strip.split('=', 2)
        h.merge(p[0] ? {p[0].to_sym => p[1]} : {})
      end
    end
  end
end
