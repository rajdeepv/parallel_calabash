require 'tempfile'
require 'parallel'
require "parallel_calabash/version"
require 'parallel_calabash/adb_helper'
require 'parallel_calabash/runner'
require "rbconfig"

module ParallelCalabash

  WINDOWS = (RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  class << self

    def run(options)
      number_of_processes = number_of_connected_devices
      raise "\n**** NO DEVICE FOUND ****\n" if number_of_processes==0
      puts "*******************************"
      puts " #{number_of_processes} DEVICES FOUND"
      puts "*******************************"
      run_tests_in_parallel(number_of_processes, options)
    end

    def run_tests_in_parallel(number_of_processes, options)
      test_results = nil
      report_time_taken do
        groups = feature_groups(options[:feature_folder], number_of_processes)
        puts "#{number_of_processes} processes for #{groups.flatten.size} features"
        test_results = Parallel.map(groups, :in_threads => groups.size) do |group|
          runner.run_tests(group, groups.index(group), options)
        end
        report_results(test_results)
      end

      Kernel.exit(1) if any_test_failed?(test_results)
    end

    def any_test_failed?(test_results)
      test_results.any? { |result| result[:exit_status] != 0 }
    end

    def report_results(test_results)
      results = runner.find_results(test_results.map { |result| result[:stdout] }.join(''))
      puts ""
      puts runner.summarize_results(results)
    end


    def runner
      ParallelCalabash::Runner
    end

    def report_time_taken
      start = Time.now
      yield
      puts "\nTook #{Time.now - start} seconds"
    end

    def number_of_connected_devices
      ParallelCalabash::AdbHelper.connected_devices.size
    end

    def feature_groups(feature_folder, group_size)
      files = feature_files_in_folder feature_folder
      min_number_files_per_group = files.size/group_size
      remaining_number_of_files = files.size % group_size
      groups = Array.new(group_size) { [] }
      groups.each do |group|
        min_number_files_per_group.times { group << files.delete_at(0) }
      end
      unless remaining_number_of_files==0
        groups[0..(remaining_number_of_files-1)].each do |group|
          group << files.delete_at(0)
        end
      end
      groups.reject(&:empty?)
    end

    def feature_files_in_folder feature_dir
      if File.directory?(feature_dir.first)
        files = Dir[File.join(feature_dir, "**{,/*/**}/*")].uniq
        files.grep(/\.feature$/)
      end
    end

  end
end
