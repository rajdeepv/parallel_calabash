require 'spec_helper'
require 'parallel_calabash'

describe ParallelCalabash::Runner do
  describe :command_for_process do
    it 'should return command with env variables' do
      ParallelCalabash::AdbHelper.should_receive(:device_for_process).with(0).and_return(["4d00fa3cb814c03f", "GT_N7100"])
      expect(ParallelCalabash::Runner.command_for_process(0, 'base_command')).to eq \
      "AUTOTEST=1;export AUTOTEST;ADB_DEVICE_ARG=4d00fa3cb814c03f;export ADB_DEVICE_ARG;DEVICE_INFO=GT_N7100;export DEVICE_INFO;TEST_PROCESS_NUMBER=1;export TEST_PROCESS_NUMBER;base_command"
    end
  end


  describe :execute_command_for_process do
    it 'should execute the command with correct env variables set and return exit status 0 when command gets executed successfully' do
      ParallelCalabash::AdbHelper.should_receive(:device_for_process).with(3).and_return("DEVICE3")
      expect(ParallelCalabash::Runner.execute_command_for_process(3,'echo $ADB_DEVICE_ARG;echo $TEST_PROCESS_NUMBER',true)).to eq ({:stdout=>"DEVICE3\n4\n", :exit_status=>0})
    end

    it 'should return exit status of 1' do
      expect(ParallelCalabash::Runner.execute_command_for_process(3,"ruby -e 'exit(1)'",true)).to eq ({:stdout=>"", :exit_status=>1})
    end
  end

end