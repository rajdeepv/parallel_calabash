require 'spec_helper'
require 'minitest/mock'
require 'parallel_calabash/android_helper'

describe ParallelCalabash::AdbHelper do

  describe :device_id_and_model do
    it 'should not match any devices in list of devices attached line' do
      expect(ParallelCalabash::AdbHelper.new([]).device_id_and_model("List of devices attached")).to eq nil
    end

    it 'should match devices if there is a space after the word device' do
      expect(ParallelCalabash::AdbHelper.new([]).device_id_and_model("emulator-5554  device ")).to eq \
         ["emulator-5554", nil]
    end

    it 'should match devices if there is not a space after the word device' do
      expect(ParallelCalabash::AdbHelper.new([]).device_id_and_model("emulator-5554  device")).to eq \
         ["emulator-5554", nil]
    end

    it 'should not match a device if it is an empty line' do
      expect(ParallelCalabash::AdbHelper.new([]).device_id_and_model("")).to eq nil
    end

    it 'should match physical devices' do
      output = "192.168.56.101:5555 device product:vbox86p model:device1 device:vbox86p"
      expect(ParallelCalabash::AdbHelper.new([]).device_id_and_model(output)).to eq ["192.168.56.101:5555", "device1"]
    end
  end

  describe :filter_device do
    it 'should return devices if no filter is specified' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.new([]).filter_device(device)).to eq device
    end

    it 'should match devices that match the filter' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.new(["device1"]).filter_device(device)).to eq device
    end

    it 'should not return devices that do not match the filter' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.new(["notmatching"]).filter_device(device)).to eq nil
    end

    it 'can also match on ip address' do
      device = ["192.168.56.101:5555", "device1"]
      expect(ParallelCalabash::AdbHelper.new(["192.168.56.101"]).filter_device(device)).to eq device
    end
  end
  describe :connected_devices_with_model_info do

    it 'should return device_id, device_name and screenshot_prefix details' do
      adb_helper = ParallelCalabash::AdbHelper.new([])
      def adb_helper.adb_devices_l
        "List of devices attached \n192.168.57.101:5555    device product:vbox86p model:device2 device:vbox86p\n192.168.57.102:5555    device product:vbox86p model:device3 device:vbox86p\n\n"
      end
      expect(adb_helper.connected_devices_with_model_info).to eq [["192.168.57.101:5555", "device2", "192_168_57_101_"], ["192.168.57.102:5555", "device3", "192_168_57_102_"]]
    end

  end
end