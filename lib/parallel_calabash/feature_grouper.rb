require 'json'
module ParallelCalabash
  class FeatureGrouper

    DEVICE_TAG_FILTER_REGEX = /([^:]+):([^,]+)(?:,([^,]+))*/

    class << self

      def feature_groups(options, group_size, device_info=[])
        return concurrent_feature_groups(options[:feature_folder], group_size) if options[:concurrent]
        return ensure_tag_for_device_scenario_groups(group_size, options, device_info) if options[:features_device_specific]
        return scenario_groups(group_size, options) if options[:group_by_scenarios]
        return feature_groups_by_weight(options[:feature_folder], group_size, options[:distribution_tag]) if options[:distribution_tag]
        feature_groups_by_feature_files(options[:feature_folder], group_size)
      end

      def feature_groups_by_scenarios(features_scenarios, group_size)
        puts "Scenarios: #{features_scenarios.size}"
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
        (0...number_of_groups).each { groups << feature_files_in_folder(feature_folder) }
        groups
      end

      def feature_groups_by_feature_files(feature_folder, group_size)
        files = feature_files_in_folder feature_folder
        groups = group_creator(group_size, files)
        groups.reject(&:empty?)
      end

      def group_creator(group_size, files)
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

      def generate_distribution_data(options)
        generate_dry_run_report options
        raise 'Can not create dry run for scenario distribution' unless File.exists?('parallel_calabash_dry_run.json')
        JSON.parse(File.read('parallel_calabash_dry_run.json'))
      end

      def ensure_tag_for_device_scenario_groups(group_size, options, device_info)
        device_tag_filters = parse_device_tag_filters(options[:features_device_specific])
        distribution_data = generate_distribution_data(options)
        groups = Array.new(group_size) { [] }
        device_info.map(&:first).each_with_index do |device_id, device_index|
          matching_tags = device_tag_filters.map do |tag, device_ids|
            tag unless device_ids.select { |curr_id| device_id.start_with?(curr_id) }.empty?
          end.compact
          ensure_for_device_index_if_necessary(device_index, distribution_data, matching_tags)
        end
        distribute_across_groups_for_devices(groups, distribution_data)
        groups
      end

      def ensure_for_device_index_if_necessary(device_index, distribution_data, matching_tags)
        distribution_data.each do |feature|
          feature_matched = tag_match(feature, matching_tags)
          feature['elements'].each do |scenario|
            scenario_matched = tag_match(scenario, matching_tags)
            if scenario['keyword'] == 'Scenario'
              if feature_matched || scenario_matched
                ensure_for_device_index(device_index, scenario)
              end
            elsif scenario['keyword'] == 'Scenario Outline'
              if scenario['examples']
                scenario['examples'].each do |example|
                  if tag_match(example, matching_tags) || feature_matched || scenario_matched
                    ensure_for_device_index(device_index, example)
                  end
                end
              else
                if feature_matched || scenario_matched
                  ensure_for_device_index(device_index, scenario)
                end
              end
            end
          end
        end
      end

      def distribute_across_groups_for_devices(groups, distribution_data)
        [true, false].each do |device_specific|
          distribution_data.each do |feature|
            feature_uri = feature['uri']
            feature['elements'].each do |scenario|
              if scenario['keyword'] == 'Scenario'
                distribute_for_devices(groups, feature_uri, scenario, device_specific)
              elsif scenario['keyword'] == 'Scenario Outline'
                if scenario['examples']
                  scenario['examples'].each do |example|
                    distribute_for_devices(groups, feature_uri, example, device_specific)
                  end
                else
                  distribute_for_devices(groups, feature_uri, scenario, device_specific)
                end
              end
            end
          end
        end
      end

      def distribute_for_devices(groups, feature_uri, element, device_specific)
        if element['device-specific-indexes'] && device_specific
          group = element['device-specific-indexes'].map { |device_index| groups[device_index] }.min_by(&:size)
          group << "#{feature_uri}:#{element['line']}"
        elsif !(element['device-specific-indexes'] || device_specific)
          groups.min_by(&:size) << "#{feature_uri}:#{element['line']}"
        end
      end

      def ensure_for_device_index(device_index, element)
        element['device-specific-indexes'] ||= []
        element['device-specific-indexes'] << device_index
      end

      def tag_match(element, matching_tags)
        (matching_tags - element.fetch('tags', []).map { |tag| tag['name'] }).size < matching_tags.size
      end

      def parse_device_tag_filters(raw_device_tag_filters)
        device_tag_filters = {}
        raw_device_tag_filters.each do |raw_device_tag_filter|
          unless raw_device_tag_filter =~ DEVICE_TAG_FILTER_REGEX
            raise "#{raw_device_tag_filter} not in required format. Must be e.g. @tag_name:device_id_1,device_id_2"
          end
          captures = raw_device_tag_filter.match(DEVICE_TAG_FILTER_REGEX).captures
          tag = captures.shift
          device_filters = []
          until (device_filter=captures.shift).nil?
            device_filters << device_filter
          end
          device_tag_filters[tag] = device_filters
        end
        device_tag_filters
      end

      def scenario_groups(group_size, options)
        distribution_data = generate_distribution_data(options)
        all_runnable_scenarios = distribution_data.map do |feature|
          unless feature['elements'].nil?
            feature['elements'].map do |scenario|
              if scenario['keyword'] == 'Scenario'
                "#{feature['uri']}:#{scenario['line']}"
              elsif scenario['keyword'] == 'Scenario Outline'
                if scenario['examples']
                  scenario['examples'].map { |example|
                    "#{feature['uri']}:#{example['line']}"
                  }
                else
                  "#{feature['uri']}:#{scenario['line']}" # Cope with --expand
                end
              end
            end
          end
        end.flatten.compact
        group_creator(group_size, all_runnable_scenarios)
      end

      def generate_dry_run_report(options)
        %x( cucumber #{options[:cucumber_options]} --dry-run -f json --out parallel_calabash_dry_run.json #{options[:feature_folder].join(' ')} )
      end

      def feature_files_in_folder(feature_dir_or_file)
        if File.directory?(feature_dir_or_file.first)
          files = Dir[File.join(feature_dir_or_file, '**{,/*/**}/*')].uniq
          files.grep(/\.feature$/)
        elsif feature_folder_has_single_feature?(feature_dir_or_file)
          feature_dir_or_file
        elsif File.file?(feature_dir_or_file.first)
          scenarios = File.open(feature_dir_or_file.first).collect { |line| line.split(' ') }
          scenarios.flatten
        end
      end

      def feature_folder_has_single_feature?(feature_dir)
        feature_dir.first.include?('.feature')
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
        feature_groups = Array.new(group_size).map { |e| e = [] }
        features.each do |feature|
          feature_groups[index_of_lightest_group(feature_groups)] << feature
        end
        feature_groups.reject! { |group| group.empty? }
        feature_groups.map { |group| group.map { |feature_hash| feature_hash[:feature] } }
      end

      def index_of_lightest_group(feature_groups)
        lightest = feature_groups.min { |x, y| weight_of_group(x) <=> weight_of_group(y) }
        feature_groups.index(lightest)
      end

      def weight_of_group(group)
        group.inject(0) { |sum, b| sum + b[:weight] }
      end

    end

  end

end
