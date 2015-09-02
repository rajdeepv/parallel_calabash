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

    def initialize(filter = [], user_glob = '/Users/*/.parallel-calabash')
      # Each user:
      # 1. Must have the qa user in their .ssh/allowed_keys
      # 2. Should configure the same ruby - e.g. ln -s ~qa/.rvm ~/.rvm
      # 3. Needs a .parallel-calabash like this:
      #   $ cat ~/.parallel-calabash
      #   CalabashServerPort=38003
      #   init=[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

      @filter = filter
      @user_glob = user_glob
    end

    def connected_devices_with_model_info
      # For now, just mark available users with this .file in their $HOME.
      puser_dirs = Dir.glob(@user_glob)
      configs = puser_dirs.collect { |file_name| read_config(file_name) }.compact
      configs.sort_by!{|p| p['order'] || p[:user]}
      @filter.empty? ? configs : configs.select { |c| c.keys.find{ |k| k.to_s.match(@filter.join('|')) } }
    end

    def read_config(file_name)
      user = File.basename(File.dirname(file_name))
      config = File.open(file_name) do |file|
        pairs = file.readlines.inject({}) do |h, l|
          p = l.strip.split('=', 2)
          h.merge({p[0] => p[1]})
        end
        pairs.merge({user: user})
      end
      if config.has_key?('CalabashServerPort') || config.has_key?('deviceEndpoint')
        config
      else
        puts "User #{user} must define either CalabashServerPort or deviceEndpoint in #{config}"
        nil
      end
    end
  end
end
