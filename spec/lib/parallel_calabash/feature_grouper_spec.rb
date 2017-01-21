require 'spec_helper'
require 'parallel_calabash/feature_grouper'

describe ParallelCalabash::FeatureGrouper do

  describe :feature_files_in_folder do
    it 'should find all feature files path in the given folder' do
      expect(ParallelCalabash::FeatureGrouper.feature_files_in_folder ['spec/test_data/features']).to eq \
      ["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]
    end

    it 'should find all the feature files in a rerun text file' do
      expect(ParallelCalabash::FeatureGrouper.feature_files_in_folder ['spec/test_data/rerun.txt']).to eq \
        ["features/aaa.feature:3", "features/aaa.feature:6", "features/aaa.feature:9", "features/bbb.feature:3", "features/bbb.feature:6", "features/bbb.feature:9"]
    end
  end

  describe :feature_groups do

    it 'should group all features in only one group' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => nil}, 1)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 2 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => nil}, 2)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 3 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => nil}, 3)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 4 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => nil}, 4)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/eee.feature"], ["spec/test_data/features/bbb.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"]]
    end

    it 'should divide features in 5 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => nil}, 5)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature"]]
    end

    it 'should create 1 group for concurrent 1 process' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => true}, 1)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should create 2 group for concurrent 2 processes' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features'], :concurrent => true}, 2)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"],
       ["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should create 2 group for concurrent 2 processes if single feature file is given' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups({:feature_folder => ['spec/test_data/features/aaa.feature'], :concurrent => true}, 2)).to eq \
      [["spec/test_data/features/aaa.feature"], ["spec/test_data/features/aaa.feature"]]
    end

  end

  describe :feature_weight do
    it 'should find number of occurrence of given tag in feature' do
      expect(ParallelCalabash::FeatureGrouper.weight_of_feature('spec/test_data/features/aaa.feature', '@tag1')).to eq 14
    end

    it 'should find number of occurrence of given tag in feature' do
      expect(ParallelCalabash::FeatureGrouper.weight_of_feature('spec/test_data/features/bbb.feature', '@tag1')).to eq 5
    end
  end

  describe :features_with_weights do
    it 'should give all features along with their weights' do
      expect(ParallelCalabash::FeatureGrouper.features_with_weights(['spec/test_data/features'], '@tag1')).to eq \
      [{:feature => "spec/test_data/features/aaa.feature", :weight => 14}, {:feature => "spec/test_data/features/bbb.feature", :weight => 5}, {:feature => "spec/test_data/features/ccc.feature", :weight => 4}, {:feature => "spec/test_data/features/ddd.feature", :weight => 3}, {:feature => "spec/test_data/features/eee.feature", :weight => 2}, {:feature => "spec/test_data/features/fff.feature", :weight => 0}]
    end

  end

  describe :feature_groups_by_weight do
    it 'should groups all features equally into 2 groups per their weight' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups_by_weight(['spec/test_data/features'], 2, '@tag1')).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature"]]
    end

    it 'should groups all features equally into 3 groups as per their weight' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups_by_weight(['spec/test_data/features'], 3, '@tag1')).to eq \
       [["spec/test_data/features/aaa.feature"], ["spec/test_data/features/bbb.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature"]]
    end

    it 'should groups all features equally into 4 groups as per their weight' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups_by_weight(['spec/test_data/features'], 4, '@tag1')).to eq \
      [["spec/test_data/features/aaa.feature"], ["spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature"]]
    end

    it 'should groups all features equally into 5 groups as per their weight' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups_by_weight(['spec/test_data/features'], 5, '@tag1')).to eq \
      [["spec/test_data/features/aaa.feature"], ["spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should groups all features equally into 6 groups as per their weight' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups_by_weight(['spec/test_data/features'], 6, '@tag1')).to eq \
      [["spec/test_data/features/aaa.feature"], ["spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature"], ["spec/test_data/features/fff.feature"]]
    end
  end

  describe :scenario_groups do
    it 'should groups all @runnable scenario equally into 2 groups' do
      expected = [
          ['spec/test_data/features/aaa.feature:12', 'spec/test_data/features/aaa.feature:20', 'spec/test_data/features/aaa.feature:24', 'spec/test_data/features/bbb.feature:16'],
          ['spec/test_data/features/bbb.feature:20', 'spec/test_data/features/ccc.feature:12', 'spec/test_data/features/ddd.feature:8', 'spec/test_data/features/ddd.feature:12']
      ]
      actual = ParallelCalabash::FeatureGrouper.scenario_groups(2, {:feature_folder => ['spec/test_data/features'], :cucumber_options => '--tags @runnable'})
      expect(actual).to eq(expected)
    end

    it 'should groups all @runnable scenario equally into 3 groups' do
      expected = [
          ['spec/test_data/features/aaa.feature:12', 'spec/test_data/features/aaa.feature:20', 'spec/test_data/features/ddd.feature:8'],
          ['spec/test_data/features/aaa.feature:24', 'spec/test_data/features/bbb.feature:16', 'spec/test_data/features/ddd.feature:12'],
          ['spec/test_data/features/bbb.feature:20', 'spec/test_data/features/ccc.feature:12']
      ]
      actual = ParallelCalabash::FeatureGrouper.scenario_groups(3, {:feature_folder => ['spec/test_data/features'], :cucumber_options => '--tags @runnable'})
      expect(actual).to eq(expected)
    end

    it 'should groups all @runnable scenario equally into 4 groups' do
      actual = ParallelCalabash::FeatureGrouper.scenario_groups(4, {:feature_folder => ['spec/test_data/features'], :cucumber_options => '--tags @runnable'})
      expected = [
          ['spec/test_data/features/aaa.feature:12', 'spec/test_data/features/aaa.feature:20'],
          ['spec/test_data/features/aaa.feature:24', 'spec/test_data/features/bbb.feature:16'],
          ['spec/test_data/features/bbb.feature:20', 'spec/test_data/features/ccc.feature:12'],
          ['spec/test_data/features/ddd.feature:8', 'spec/test_data/features/ddd.feature:12']
      ]
      expect(actual).to eq(expected)
    end

  end

  describe :ensure_tag_for_devices do

    it 'only distributes device-A-specific tags to device A' do
      opts = {
          feature_folder: ['spec/test_data/features_device_specific'],
          cucumber_options: '--tags @any_device,@device_specific',
          features_device_specific: ['@device_specific:deviceAId']
      }
      devices = [
          ['deviceAId', nil],
          ['deviceBId', nil]
      ]
      actual = ParallelCalabash::FeatureGrouper.ensure_tag_for_device_scenario_groups(devices.size, opts, devices)
      expected = [
          ['spec/test_data/features_device_specific/device_specific.feature:5', 'spec/test_data/features_device_specific/device_specific.feature:9'],
          ['spec/test_data/features_device_specific/any_device.feature:4', 'spec/test_data/features_device_specific/any_device.feature:7']
      ]
      expect(actual).to eq(expected)
    end

    it 'only distributes device-B-specific tags to device B' do
      opts = {
          feature_folder: ['spec/test_data/features_device_specific'],
          cucumber_options: '--tags @any_device,@device_specific',
          features_device_specific: ['@device_specific:deviceBId']
      }
      devices = [
          ['deviceAId', nil],
          ['deviceBId', nil]
      ]
      actual = ParallelCalabash::FeatureGrouper.ensure_tag_for_device_scenario_groups(devices.size, opts, devices)
      expected = [
          ['spec/test_data/features_device_specific/any_device.feature:4', 'spec/test_data/features_device_specific/any_device.feature:7'],
          ['spec/test_data/features_device_specific/device_specific.feature:5', 'spec/test_data/features_device_specific/device_specific.feature:9']
      ]
      expect(actual).to eq(expected)
    end

    it 'handles unmatched device filters' do
      opts = {
          feature_folder: ['spec/test_data/features_device_specific'],
          cucumber_options: '--tags @any_device',
          features_device_specific: ['@multiple:deviceXId,deviceYId']
      }
      devices = [
          ['deviceAId', nil],
          ['deviceBId', nil]
      ]
      actual = ParallelCalabash::FeatureGrouper.ensure_tag_for_device_scenario_groups(devices.size, opts, devices)
      expected = [
          ['spec/test_data/features_device_specific/any_device.feature:4'],
          ['spec/test_data/features_device_specific/any_device.feature:7']
      ]
      expect(actual).to eq(expected)
    end

    it 'handles multiple ensure filters' do
      opts = {
          feature_folder: ['spec/test_data/features_device_specific'],
          cucumber_options: '--tags @any_device,@multiple_matches',
          features_device_specific: ['@multiple:deviceAId', '@any_device:deviceBId']
      }
      devices = [
          ['deviceAId', nil],
          ['deviceBId', nil]
      ]
      actual = ParallelCalabash::FeatureGrouper.ensure_tag_for_device_scenario_groups(devices.size, opts, devices)
      expected = [
          ['spec/test_data/features_device_specific/multiple_devices.feature:5', 'spec/test_data/features_device_specific/multiple_devices.feature:14', 'spec/test_data/features_device_specific/multiple_devices.feature:18'],
          ['spec/test_data/features_device_specific/any_device.feature:4', 'spec/test_data/features_device_specific/any_device.feature:7', 'spec/test_data/features_device_specific/multiple_devices.feature:19']
      ]
      expect(actual).to eq(expected)
    end

    it 'prioritises distribution of device-specific tags before non-specific tags' do
      opts = {
          feature_folder: ['spec/test_data/features_device_specific'],
          cucumber_options: '--tags @multiple_matches',
          features_device_specific: ['@multiple:deviceAId,deviceBId']
      }
      devices = [
          ['deviceAId', nil],
          ['deviceBId', nil]
      ]
      actual = ParallelCalabash::FeatureGrouper.ensure_tag_for_device_scenario_groups(devices.size, opts, devices)
      expected = [
          ['spec/test_data/features_device_specific/multiple_devices.feature:5', 'spec/test_data/features_device_specific/multiple_devices.feature:18'],
          ['spec/test_data/features_device_specific/multiple_devices.feature:14', 'spec/test_data/features_device_specific/multiple_devices.feature:19']
      ]
      expect(actual).to eq(expected)
    end

  end

end
