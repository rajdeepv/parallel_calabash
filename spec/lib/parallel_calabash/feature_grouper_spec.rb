require 'spec_helper'

require 'parallel_calabash/feature_grouper'

describe ParallelCalabash::FeatureGrouper do

  describe :feature_files_in_folder do
    it 'should find all feature files path in the given folder' do
      expect(ParallelCalabash::FeatureGrouper.feature_files_in_folder ['spec/test_data/features']).to eq \
      ["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]
    end
  end

  describe :feature_groups do

    it 'should group all features in only one group' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['spec/test_data/features'], 1)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 2 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['spec/test_data/features'], 2)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature", "spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature", "spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 3 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['spec/test_data/features'], 3)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature", "spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature", "spec/test_data/features/fff.feature"]]
    end

    it 'should divide features in 4 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['spec/test_data/features'], 4)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/eee.feature"], ["spec/test_data/features/bbb.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"]]
    end

    it 'should divide features in 5 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['spec/test_data/features'], 5)).to eq \
      [["spec/test_data/features/aaa.feature", "spec/test_data/features/fff.feature"], ["spec/test_data/features/bbb.feature"], ["spec/test_data/features/ccc.feature"], ["spec/test_data/features/ddd.feature"], ["spec/test_data/features/eee.feature"]]
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


end