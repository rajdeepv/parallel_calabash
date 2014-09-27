require_relative 'adb_helper'
require 'shellwords'
require "rbconfig"
require 'rake/dsl_definition'
require 'rake'

module ParallelCalabash
  class Runner
    class << self
      def base_command
        'calabash-android run'
      end

      def run_tests(test_files, process_number, options)
        combined_scenarios = test_files

        sanitized_test_files = combined_scenarios.map { |val| WINDOWS ? "\"#{val}\"" : Shellwords.escape(val) }

        options[:env] ||= {}
        options[:env] = options[:env].merge({'AUTOTEST' => '1'}) if $stdout.tty? # display color when we are in a terminal


        cmd = [
            base_command,
            options[:apk_path],
            options[:cucumber_options],
            *sanitized_test_files
        ].compact.join(' ')
        device_for_current_process = ParallelCalabash::AdbHelper.device_for_process process_number
        cmd = cmd + " ADB_DEVICE_ARG=#{device_for_current_process}"
        p cmd
        execute_command(cmd, process_number, options)
      end

      def execute_command(cmd, process_number, options)
        env = (options[:env] || {}).merge(
            "TEST_PROCESS_NUMBER" => (process_number+1).to_s
        )
        cmd = "nice #{cmd}" if options[:nice]
        execute_command_and_capture_output(env, cmd, options[:serialize_stdout])
      end

      def execute_command_and_capture_output(env, cmd, silence)
        # make processes descriptive / visible in ps -ef
        separator = (WINDOWS ? ' & ' : ';')
        exports = env.map do |k,v|
          # if WINDOWS
          #   "(SET \"#{k}=#{v}\")"
          # else
            "#{k}=#{v};export #{k}"
          # end
        end.join(separator)
        cmd = "#{exports}#{separator}#{cmd}"

        output = open("|#{cmd}", "r") { |output| capture_output(output, silence) }
        exitstatus = $?.exitstatus

        {:stdout => output, :exit_status => exitstatus}
      end

      def capture_output(out, silence)
        result = ""
        loop do
          begin
            read = out.readpartial(1000000) # read whatever chunk we can get
            result << read
            unless silence
              $stdout.print read
              $stdout.flush
            end
          end
        end rescue EOFError
        result
      end


      def find_results(test_output)
        test_output.split("\n").map {|line|
          line.gsub!(/\e\[\d+m/,'')
          next unless line_is_result?(line)
          line
        }.compact
      end

      def line_is_result?(line)
        line =~scenario_or_step_result_regex or line =~ failing_scenario_regex
      end

      def summarize_results(results)
        output = []

        failing_scenarios = results.grep(failing_scenario_regex)
        if failing_scenarios.any?
          failing_scenarios.unshift("Failing Scenarios:")
          output << failing_scenarios.join("\n")
        end

        output << summary(results)

        output.join("\n\n")
      end



      def summary(results)
        sort_order = %w[scenario step failed undefined skipped pending passed]

        %w[scenario step].map do |group|
          group_results = results.grep(/^\d+ #{group}/)
          next if group_results.empty?

          sums = sum_up_results(group_results)
          sums = sums.sort_by { |word, _| sort_order.index(word) || 999 }
          sums.map! do |word, number|
            plural = "s" if word == group and number != 1
            "#{number} #{word}#{plural}"
          end
          "#{sums[0]} (#{sums[1..-1].join(", ")})"
        end.compact.join("\n")
      end

      def sum_up_results(results)
        results = results.join(' ').gsub(/s\b/,'') # combine and singularize results
        counts = results.scan(/(\d+) (\w+)/)
        counts.inject(Hash.new(0)) do |sum, (number, word)|
          sum[word] += number.to_i
          sum
        end
      end

      private

      def scenario_or_step_result_regex
        /^\d+ (steps?|scenarios?)/
      end

      def failing_scenario_regex
        /^cucumber features\/.+:\d+/
      end

    end
  end
end