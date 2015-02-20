module ParallelCalabash
  class FeatureGrouper

    class << self

      def feature_groups(feature_folder, group_size,weighing_factor = nil, concurrent = nil)
        if concurrent.nil?
          weighing_factor.nil? ? feature_groups_by_feature_files(feature_folder, group_size) :  feature_groups_by_weight(feature_folder, group_size,weighing_factor)
        else
          concurrent_feature_groups(feature_folder, group_size)
        end
      end

      def feature_groups_by_scenarios(features_scenarios,group_size)
        puts features_scenarios.size
        min_number_scenarios_per_group = features_scenarios.size/group_size
        remaining_number_of_scenarios = features_scenarios.size % group_size
        groups = Array.new(group_size) { [] }
        groups.each do |group|
          min_number_scenarios_per_group.times { group << features_scenarios.delete_at(0) }
        end
        unless remaining_number_of_scenarios==0
          groups[0..(remaining_number_of_scenarios-1)].each do |group|
            group << features_scenarios.delete_at(0)
          end
        end
        groups.reject(&:empty?)
      end

      def concurrent_feature_groups(feature_folder, number_of_groups)
        groups = []
        (0...number_of_groups).each{ groups << feature_files_in_folder(feature_folder) }
        groups
      end

      def feature_groups_by_feature_files(feature_folder, group_size)
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

      def feature_files_in_folder(feature_dir)
        if File.directory?(feature_dir.first)
          files = Dir[File.join(feature_dir, "**{,/*/**}/*")].uniq
          files.grep(/\.feature$/)
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