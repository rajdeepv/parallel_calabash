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
        groups = FeatureGrouper.feature_groups(options[:feature_folder], number_of_processes,options[:distribution_tag])
        puts "#{number_of_processes} processes for #{groups.flatten.size} features"
        test_results = Parallel.map(groups, :in_threads => groups.size) do |group|
          Runner.run_tests(group, groups.index(group), options)
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
      puts "\nTook #{Time.now - start} seconds"
    end

  end
end
