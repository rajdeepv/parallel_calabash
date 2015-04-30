require 'spec_helper'

require 'parallel_calabash/adb_helper'
describe ParallelCalabash::AdbHelper do

  describe :filter_device do
    it 'should return devices if no filter is specified' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.filter_device(device, [])).to eq device
    end

    it 'should match devices that match the filter' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.filter_device(device, ["device1"])).to eq device
    end

    it 'should not return devices that do not match the filter' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.filter_device(device, ["notmatching"])).to eq nil
    end

    it 'can also match on ip address' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.filter_device(device, ["192.168.56.101"])).to eq device
    end
  end

end