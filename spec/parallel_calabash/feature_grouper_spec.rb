require 'spec_helper'

require 'parallel_calabash/feature_grouper'

describe ParallelCalabash::FeatureGrouper do

  before(:all) do
    `mkdir -p test_files/test_subfolder`
    5.times do |index|
      `touch test_files/#{index}.feature test_files/#{index}.txt`
    end
  end

  after(:all) do
    `rm -rf test_files`
  end

  describe :feature_files_in_folder do
    it 'should find all feature files path in the given folder' do
      expect(ParallelCalabash::FeatureGrouper.feature_files_in_folder ['test_files'] ).to eq \
      ["test_files/0.feature", "test_files/1.feature", "test_files/2.feature", "test_files/3.feature", "test_files/4.feature"]
    end

    it 'should return no files when there are no feature files in given directory' do
      expect(ParallelCalabash::FeatureGrouper.feature_files_in_folder ['test_files/test_subfolder'] ).to eq []
    end


  end

  describe :feature_groups do

    it 'should group all features in only one group' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['test_files'],1)).to eq \
      [["test_files/0.feature", "test_files/1.feature", "test_files/2.feature", "test_files/3.feature", "test_files/4.feature"]]
    end

    it 'should divide features in 2 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['test_files'],2)).to eq \
      [["test_files/0.feature", "test_files/1.feature", "test_files/4.feature"], ["test_files/2.feature", "test_files/3.feature"]]
    end

    it 'should divide features in 3 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['test_files'],3)).to eq \
      [["test_files/0.feature", "test_files/3.feature"], ["test_files/1.feature", "test_files/4.feature"], ["test_files/2.feature"]]
    end

    it 'should divide features in 4 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['test_files'],4)).to eq \
      [["test_files/0.feature", "test_files/4.feature"], ["test_files/1.feature"], ["test_files/2.feature"], ["test_files/3.feature"]]
    end

    it 'should divide features in 5 groups' do
      expect(ParallelCalabash::FeatureGrouper.feature_groups(['test_files'],5)).to eq \
      [["test_files/0.feature"], ["test_files/1.feature"], ["test_files/2.feature"], ["test_files/3.feature"], ["test_files/4.feature"]]
    end

  end

end