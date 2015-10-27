class <<RunLoop::SimControl
  def terminate_all_sims
    puts "Patched terminate_all_sims"
  end
end

class RunLoop::Instruments
  INSTRUMENTS_FIND_PIDS_CMD = "ps x -o pid,command | grep -v grep | grep 'instruments -w #{ENV["DEVICE_TARGET"]}'"
end

class <<RunLoop::CoreSimulator
  def quit_simulator
    puts "Patched quit_simulator"
  end
end

class RunLoop::SimControl
  remove_method :ensure_accessibility, :ensure_software_keyboard, :quit_sim
  def ensure_accessibility device
    puts "patched ensure_accessibility"
  end
  def ensure_software_keyboard device
    puts "patched ensure_software_keyboard"
  end

  def quit_sim opts={}
    puts "Patched quit_sim"
  end
end
