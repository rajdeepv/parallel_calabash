module ParallelCalabash
  class TimeoutErr < RuntimeError
  end

  class Connectivity
    def self.ensure launcher
      raise "ping_app not present in launcher!" unless launcher.respond_to? "ping_app"
      connected = false
      until connected do
        begin
          Timeout::timeout(90, TimeoutErr) do
            until connected
              begin
                connected = (launcher.ping_app == '200')
                break if connected
              rescue Exception => e
                puts "Retry connection after 1 second"
              ensure
                sleep 1 unless connected
              end
            end
          end
        rescue TimeoutErr => e
          puts 'Timed out... exiting'
          stop
        end
      end
    end
  end
end