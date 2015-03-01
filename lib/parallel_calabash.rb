require 'tempfile'
require 'parallel'
require 'parallel_calabash/version'
require 'parallel_calabash/adb_helper'
require 'parallel_calabash/runner'
require 'parallel_calabash/feature_grouper'
require 'parallel_calabash/result_formatter'
require 'rbconfig'

module ParallelCalabash

  WINDOWS = (RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  class << self

    def number_of_processes_to_start
      number_of_processes = AdbHelper.number_of_connected_devices
      raise "\n**** NO DEVICE FOUND ****\n" if number_of_processes==0
      puts "*******************************"
      puts " #{number_of_processes} DEVICES FOUND"
      puts "*******************************"
      number_of_processes
    end

    def run_tests_in_parallel(options)
      number_of_processes = number_of_processes_to_start

      test_results = nil
      report_time_taken do
        groups = FeatureGrouper.feature_groups(options, number_of_processes)
        threads = groups.size

        test_results = Parallel.map_with_index(groups, :in_threads => threads) do |group, index|
          Runner.run_tests(group, index, options)
        end
        ResultFormatter.report_results(test_results)
      end

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
