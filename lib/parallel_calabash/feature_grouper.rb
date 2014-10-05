module ParallelCalabash
  class FeatureGrouper

    class << self

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
end