#encoding: utf-8

module UnitedWorkers
  class WorkerSpawner
    def self.start(bootstrap, instance_count, channel_id)
      instance_count.times { launch(bootstrap, channel_id) }
    end

    def self.launch(bootstrap, channel_id)
      pid = fork do
        UnitedWorkers::Monitor.start_monitor(channel_id, Process.pid, "process_#{Process.pid}")
        bootstrap.call
        UnitedWorkers::Monitor.stop_monitor(channel_id, "process_#{Process.pid}")
      end
      Process.detach pid
      register(bootstrap, pid, channel_id)
      pid
    end

    def self.register(bootstrap, pid, channel_id)
      UnitedWorkers::Queue.new_fanout_queue(channel_id).tap do |queue|
        queue.subscribe do |_, __, message|
          m = UnitedWorkers::Queue.unpack(message)
          if m[:type] == :task_end && m[:status] == :killed && m[:pid] == pid && m[:task_id] == "process_#{pid}"
            UnitedWorkers::Logger.log("A worker with PID #{pid} was killed. Restarting")
            launch(bootstrap, channel_id)
            queue.channel.close
            queue.channel.connection.close
          end
        end
      end
    end

    def self.test
      begin
        UnitedWorkers::Monitor.launch(:monitor)
      rescue => e
        p e
      end
      bootstrap = lambda { $0="A Worker"; sleep(300); UnitedWorkers::Logger.log('Spawning a worker') }
      start(bootstrap, 10, :monitor)
    end
  end
end
