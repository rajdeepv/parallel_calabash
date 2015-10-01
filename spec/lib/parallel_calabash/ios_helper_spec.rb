require 'spec_helper'
require 'minitest/mock'
require 'parallel_calabash/ios_helper'

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
      expect(ParallelCalabash::IosHelper.new([], {}, {NO_OF_DEVICES:2, DEVICE_TARGET: "iPhoneSimulator"}, '')
                 .compute_simulators)
          .to eq [{DEVICE_TYPE: "iPhoneSimulator", DEVICE_TARGET: "PCalSimulator_1", CALABASH_SERVER_PORT: 28000},
                  {DEVICE_TYPE: "iPhoneSimulator", DEVICE_TARGET: "PCalSimulator_2", CALABASH_SERVER_PORT: 28001}]
    end

    it 'allocates other ports to users' do
      expect(ParallelCalabash::IosHelper.new([], {}, {NO_OF_DEVICES:2, CALABASH_SERVER_PORT:100, DEVICE_TARGET: "iPhoneSimulator8.4"}, '')
                 .compute_simulators)
          .to eq [{DEVICE_TYPE: "iPhoneSimulator8.4", DEVICE_TARGET: "PCalSimulator_1", CALABASH_SERVER_PORT: 100},
                  {DEVICE_TYPE: "iPhoneSimulator8.4", DEVICE_TARGET: "PCalSimulator_2", CALABASH_SERVER_PORT: 101}]
    end
  end

  describe :test_compute_devices do
    it 'fails with no devices' do
      expect { ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}]}, 'name [udon\'t]')
                   .compute_devices }
          .to raise_error(RuntimeError)
    end

    it 'allocates users to devices' do
      expect(ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}]}, 'name [udid]')
                 .compute_devices)
          .to eq [{DEVICE_TARGET: "udid", CALABASH_SERVER_PORT: 28000, DEVICE: true}]
    end

    it 'allocates users init to devices' do
      expect(ParallelCalabash::IosHelper.new([], {}, {DEVICES: [{DEVICE_TARGET: 'udid'}], CALABASH_SERVER_PORT: 100}, 'name [udid]')
                 .compute_devices)
          .to eq [{DEVICE_TARGET: "udid", CALABASH_SERVER_PORT: 100, DEVICE: true}]
    end
  end
end