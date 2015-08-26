require 'spec_helper'

require 'parallel_calabash/adb_helper'
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
end

describe ParallelCalabash::IosHelper do
  describe :finds_user_configs do
    it 'should return all user configs' do
      expect(ParallelCalabash::IosHelper.new(File.dirname(__FILE__) + "/users/*/config")
                 .connected_devices_with_model_info).to eq [{"CalabashServerPort"=>"6800", :user=>"user1"}, {"CalabashServerPort"=>"6802", :user=>"user2"}]
    end
  end
end