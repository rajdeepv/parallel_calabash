require 'tempfile'
require 'parallel'
require 'parallel_calabash/version'
require 'parallel_calabash/android_helper'
require 'parallel_calabash/ios_helper'
require 'parallel_calabash/android_runner'
require 'parallel_calabash/ios_runner'
require 'parallel_calabash/ios/xcrun_helper'
require 'parallel_calabash/feature_grouper'
require 'parallel_calabash/result_formatter'
require 'parallel_calabash/connectivity'
require 'rbconfig'

module ParallelCalabash
  WINDOWS = (RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)

  class ParallelCalabashApp

    def initialize(options)
      @options = options
      @helper = if options.has_key?(:apk_path)
                  ParallelCalabash::AdbHelper.new(options[:filter])
                else
                  ParallelCalabash::IosHelper.new(
                      options[:filter],
                      {
                          DEVICE_TARGET: options[:device_target],
                          DEVICE_ENDPOINT: options[:device_endpoint],
                      },
                      options[:ios_config]
                  )
                end
      @runner = if options.has_key?(:apk_path)
                  ParallelCalabash::AndroidRunner.new(@helper, options[:mute_output])
                else
                  ParallelCalabash::IosRunner.new(@helper, options[:mute_output], options[:skip_ios_ping_check])
                end
    end


    def number_of_processes_to_start
      number_of_processes = @helper.number_of_connected_devices
      raise "\n**** NO DEVICE FOUND ****\n" if number_of_processes==0
      puts '*******************************'
      puts " #{number_of_processes} DEVICES FOUND:"
      puts @helper.connected_devices_with_model_info
      puts '*******************************'
      number_of_processes
    end

    def run_tests_in_parallel
      @runner.prepare_for_parallel_execution
      number_of_processes = number_of_processes_to_start
      test_results = nil
      report_time_taken do
        groups = FeatureGrouper.feature_groups(@options, number_of_processes)
        threads = groups.size
        puts "Running with #{threads} threads: #{groups}"
        complete = []
        test_results = Parallel.map_with_index(
            groups,
            :in_threads => threads,
            :finish => lambda { |_, i, _|  complete.push(i); print complete, "\n" }) do |group, index|
          @runner.run_tests(group, index, @options)
        end
        puts 'All threads complete'
        ResultFormatter.report_results(test_results)
      end
      @runner.prepare_for_parallel_execution
      puts 'Parallel run complete'
      Kernel.exit(1) if any_test_failed?(test_results)
    end

    def any_test_failed?(test_results)
      test_results.any? { |result| result[:exit_status] != 0 }
    end

    def report_time_taken
      start = Time.now
      yield
      time_in_sec = Time.now - start
      mm, ss = time_in_sec.divmod(60)
      puts "\nTook #{mm} Minutes, #{ss.round(2)} Seconds"
    end
  end
end
