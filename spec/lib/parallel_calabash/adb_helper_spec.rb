require 'spec_helper'
require 'minitest/mock'
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

describe ParallelCalabash::IosHelper do
  describe :test_apply_filter do
    it 'Does nothing with no filters' do
      expect(ParallelCalabash::IosHelper.new([], nil, {}, '')
                 .apply_filter([{any: 'thing'}, {what: 'soever'}]))
          .to eq [{any: 'thing'}, {what: 'soever'}]
    end

    it 'Excludes anything not mentioned' do
      expect(ParallelCalabash::IosHelper.new(['yes'], nil, {}, '')
                 .apply_filter([{any: 'thing'}, {what: 'soever'}]))
          .to eq []
    end

    it 'Excludes only things not mentioned' do
      expect(ParallelCalabash::IosHelper.new(['aa', 'bb'], nil, {}, '')
                 .apply_filter([{eaa: 'thing', ecc: 'thing'}, {what: 'aa', so: 'ebb'}, {ever: 'thing'}]))
          .to eq [{eaa: 'thing', ecc: 'thing'}, {what: 'aa', so: 'ebb'}]
    end
  end

  describe :test_remove_unconnected_devices do
    it 'Removes unconnected devices' do
      expect(ParallelCalabash::IosHelper.new(nil, nil, {},
                                             "name [udid1]\nname2 [udid2]\nname3 [udid-unknown]")
                 .remove_unconnected_devices([{DEVICE_TARGET: 'udid1'},
                                              {DEVICE_TARGET: 'udid2'},
                                              {DEVICE_TARGET: 'udid-unplugged'}]))
          .to eq [{DEVICE_TARGET: "udid1"}, {DEVICE_TARGET: "udid2"}]
    end
  end

  describe :test_compute_simulators do
    it 'allocates ports to users' do
      expect(ParallelCalabash::IosHelper.new([], {}, {USERS:['a', 'b'], INIT:'foo'}, '')
                 .compute_simulators)
          .to eq [{USER:'a', INIT:'foo', CALABASH_SERVER_PORT: 28000},
                  {USER:'b', INIT:'foo', CALABASH_SERVER_PORT: 28001}]
    end

    it 'allocates other ports to users' do
      expect(ParallelCalabash::IosHelper.new([], {}, {USERS:['a', 'b'], INIT:'foo', CALABASH_SERVER_PORT:100}, '')
                 .compute_simulators)
          .to eq [{USER:'a', INIT:'foo', CALABASH_SERVER_PORT: 100},
                  {USER:'b', INIT:'foo', CALABASH_SERVER_PORT: 101}]
    end
  end

  describe :test_compute_devices do
    it 'returns nothing with no users' do
      expect(ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}]}, 'name [udid]')
                 .compute_devices)
          .to eq []
    end

    it 'fails with no devices' do
      expect { ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}],
                                                        USERS: ['a']}, 'name [udon\'t]')
                   .compute_devices }
          .to raise_error(RuntimeError)
    end

    it 'allocates users to devices' do
      expect(ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}],
                                                      USERS: ['a', 'b']}, 'name [udid]')
                 .compute_devices)
          .to eq [{DEVICE_TARGET: "udid", USER: "a", INIT: ""}]
    end

    it 'allocates users init to devices' do
      expect(ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}],
                                                      USERS: ['a', 'b'],
                                                      INIT: 'start'}, 'name [udid]')
                 .compute_devices)
          .to eq [{DEVICE_TARGET: "udid", USER: "a", INIT: "start"}]
    end
  end
end