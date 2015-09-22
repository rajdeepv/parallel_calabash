require 'run_loop/sim_control'

# This patch is needed to work around 'simctl erase' not working on a booted device:
#  Because of RunLoop's assumptions and Mac inadequacies relating to multiple
#  users, this 'shutdown' helped our 'Before scenario' hooks.
#
# You'll want to copy this to your Cucumber project. Probably.
#
# Copyright whoever owns RunLoop, except for the hashed block which is presumably Badoo's but
# we'll let you have it because we're nice.

puts "Monkeypatch: #{__FILE__}"
RunLoop::SimControl.class_eval do
  # @!visibility private
  # Uses the `simctl erase` command to reset a simulator content and settings.
  # If no `sim_udid` is nil, _all_ simulators are reset.
  #
  # # @note This is an Xcode 6 only method. It will raise an error if called on
  #  Xcode < 6.
  #
  # @note This method will quit the simulator.
  #
  # @param [String] sim_udid The udid of the simulator that will be reset.
  #   If sim_udid is nil, _all_ simulators will be reset.
  # @raise [RuntimeError] If called on Xcode < 6.
  # @raise [RuntimeError] If `sim_udid` is not a valid simulator udid.  Valid
  #  simulator udids are determined by calling `simctl list`.
  def simctl_reset(sim_udid = nil)
    unless xcode_version_gte_6?
      fail 'this method is only available on Xcode >= 6'
    end

    quit_sim

    sim_details = sim_details(:udid)
    simctl_erase = lambda { |udid|
      # ################################################
      puts '** MONKEYPATCH Speculative shutdown - may fail harmlessly'
      shutdown_output = %x( xcrun simctl shutdown #{udid} )
      puts "** MONKEYPATCH Injected simctl_shutdown: #{shutdown_output} [#{__FILE__}]"
      # ################################################
      args = "simctl erase #{udid}".split(' ')
      Open3.popen3('xcrun', *args) do |_, stdout, stderr, wait_thr|
        out = stdout.read.strip
        err = stderr.read.strip
        if ENV['DEBUG_UNIX_CALLS'] == '1'
          cmd = "xcrun simctl erase #{udid}"
          puts __FILE__ + " sim_erase cmd #{cmd}"
          puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
        end
        wait_thr.value.success?
      end
    }

    # Call erase on all simulators
    if sim_udid.nil?
      res = []
      sim_details.each_key do |key|
        res << simctl_erase.call(key)
      end
      res.all?
    else
      if sim_details[sim_udid]
        simctl_erase.call(sim_udid)
      else
        fail "Could not find simulator with udid '#{sim_udid}'"
      end
    end
  end
end
