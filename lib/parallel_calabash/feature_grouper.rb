require 'json'
module ParallelCalabash
  class FeatureGrouper

    class << self

      def feature_groups(options, group_size)
        return concurrent_feature_groups(options[:feature_folder], group_size) if options[:concurrent]
        return scenario_groups group_size, options if options[:group_by_scenarios]
        return feature_groups_by_weight(options[:feature_folder], group_size,options[:distribution_tag]) if options[:distribution_tag]
        feature_groups_by_feature_files(options[:feature_folder], group_size)
      end

      def concurrent_feature_groups(feature_folder, number_of_groups)
        groups = []
        (0...number_of_groups).each{ groups << feature_files_in_folder(feature_folder) }
        groups
      end

      def feature_groups_by_feature_files(feature_folder, group_size)
        files = feature_files_in_folder feature_folder
        groups = group_creator group_size,files
        groups.reject(&:empty?)
      end

      def group_creator group_size, files
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
        groups.reject &:empty?
      end

      def scenario_groups group_size, options
        generate_dry_run_report options
        raise "Can not create dry run for scenario distribution" unless File.exists?("parallel_calabash_dry_run.json")
        distribution_data = JSON.parse(File.read("parallel_calabash_dry_run.json"))
        all_runnable_scenarios = distribution_data.map do |feature|
          unless feature["elements"].nil?
            feature["elements"].map do |scenario|
              if scenario["keyword"] == 'Scenario'
                "#{feature["uri"]}:#{scenario["line"]}"
              elsif scenario['keyword'] == 'Scenario Outline'
                scenario["examples"].map { |example|
                  "#{feature["uri"]}:#{example["line"]}"
                }
              end
            end
          end
        end.flatten.compact
        groups = group_creator group_size,all_runnable_scenarios
      end

      def generate_dry_run_report options
        `cucumber #{options[:cucumber_options]}  -f usage --dry-run -f json --out parallel_calabash_dry_run.json #{options[:feature_folder].join(' ')}`
      end

      def feature_files_in_folder(feature_dir)
        if File.directory?(feature_dir.first)
          files = Dir[File.join(feature_dir, "**{,/*/**}/*")].uniq
          files.grep(/\.feature$/)
        elsif File.file?(feature_dir.first)
          scenarios = File.open(feature_dir.first).collect{ |line| line.split(' ') }
          scenarios.flatten
        end
      end

      def weight_of_feature(feature_file, weighing_factor)
        content = File.read(feature_file)
        content.scan(/#{weighing_factor}\b/).size
      end

      def features_with_weights(feature_dir, weighing_factor)
        files = feature_files_in_folder feature_dir
        features_and_weight = []
        files.each do |file|
          features_and_weight << {:feature => file, :weight => weight_of_feature(file, weighing_factor)}
        end
        features_and_weight
      end

      def feature_groups_by_weight(feature_folder, group_size, weighing_factor)
        features = features_with_weights feature_folder, weighing_factor
        feature_groups = Array.new(group_size).map{|e| e = []}
        features.each do |feature|
          feature_groups[index_of_lightest_group(feature_groups)] << feature
        end
        feature_groups.reject!{|group|  group.empty?}
        feature_groups.map{|group| group.map{|feature_hash| feature_hash[:feature]}}
      end

      def index_of_lightest_group feature_groups
        lightest = feature_groups.min { |x, y| weight_of_group(x) <=> weight_of_group(y) }
        index = feature_groups.index(lightest)
      end

      def weight_of_group group
        group.inject(0) { |sum, b| sum + b[:weight] }
      end

    end

  end
end
