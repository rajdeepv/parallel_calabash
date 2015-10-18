class <<RunLoop::SimControl
  def terminate_all_sims
    puts "Patched!!"
  end
end

class <<RunLoop::CoreSimulator
  def quit_simulator
    puts "Patched!!"
  end
end

class RunLoop::SimControl
  remove_method :ensure_accessibility, :ensure_software_keyboard
  def ensure_accessibility device
  end
  def ensure_software_keyboard device
  end
end
