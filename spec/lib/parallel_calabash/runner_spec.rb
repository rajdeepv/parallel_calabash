require 'spec_helper'
require 'minitest/mock'
require 'parallel_calabash'

describe ParallelCalabash::Runner do
  describe :command_for_process do
    it 'should return command with env variables' do
      adb_helper = MiniTest::Mock.new
      adb_helper.expect(:device_for_process, ["4d00fa3cb814c03f", "GT_N7100"], [0])
      expect(ParallelCalabash::AndroidRunner.new(adb_helper, true)
                 .command_for_test(0, 'base_command', 'some.apk', '-some -options', %w(file1 file2)))
          .to eq 'AUTOTEST=1;export AUTOTEST;ADB_DEVICE_ARG=4d00fa3cb814c03f;export ADB_DEVICE_ARG;'\
                 'DEVICE_INFO=GT_N7100;export DEVICE_INFO;TEST_PROCESS_NUMBER=1;export TEST_PROCESS_NUMBER;'\
                 'SCREENSHOT_PATH=4d00fa3cb814c03f_;export SCREENSHOT_PATH;'\
                 'base_command some.apk -some -options file1 file2'
    end
  end
  
  describe :execute_command_for_process do
    adb_helper = MiniTest::Mock.new
    runner = ParallelCalabash::AndroidRunner.new(nil, true)
    it 'should execute the command with correct env variables set and return exit status 0 when command gets executed successfully' do
      expect(runner.execute_command_for_process(3, 'ADB_DEVICE_ARG=DEVICE3; export ADB_DEVICE_ARG; TEST_PROCESS_NUMBER=4; export TEST_PROCESS_NUMBER; echo $ADB_DEVICE_ARG;echo $TEST_PROCESS_NUMBER')).to eq ({:stdout=>"DEVICE3\n4\n", :exit_status=>0})
    end

    it 'should return exit status of 1' do
      expect(runner.execute_command_for_process(3,"ruby -e 'exit(1)'")).to eq ({:stdout=>'', :exit_status=>1})
    end
  end
end