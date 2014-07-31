#encoding: utf-8

class UnitedWorkers::Monitor
  @launched = false
  attr_reader :queue_id

  #This is intended to be run within the job dispatcher and live together with it. Monitor threads will belong to main dispatchec process
  def self.launch(queue_id)
    raise 'Already runnung' if @launched
    @launched = true
    @instance = UnitedWorkers::Monitor.new(queue_id)
  end

  def self.instance
    @instance
  end

  def initialize(queue_id)
    @queue_id = queue_id
    @running_tasks = {}
    @task_mutex = Mutex.new

    UnitedWorkers::Queue.get(queue_id).subscribe do |delivery_info, properties, message|
      if message[:type] && [:start_monitor, :stop_monitor].include?(message[:type].to_sym)
        monitor_message(message[:type].to_sym, message[:pid], message[:task_id])
      end
    end
  end

  def self.start_monitor(pid, task_id)
    UnitedWorkers::Queue.get(instance.queue_id).publish({type: :start_monitor, pid: pid, task_id: task_id})
  end

  def self.stop_monitor(task_id)
    UnitedWorkers::Queue.get(instance.queue_id).publish({type: :stop_monitor, task_id: task_id})
  end

  private
  def monitor_message(type, pid, task_id)
    @task_mutex.synchronize do
      if type == :start_monitor
        thread = MonitorThread.new(queue_id, pid, task_id)
        @running_tasks[task_id] = thread
        thread.start
      elsif type == :stop_monitor
        thread = @running_tasks[task_id]
        if thread
          thread.stop
          @running_tasks.delete(task_id)
        end
      end
    end
  end

  class MonitorThread
    def initialize(queue_id, pid, task_id, poll_timeout_in_seconds = 2)
      @queue_id, @pid, @task_id, @poll_timeout_in_seconds = queue_id, pid, task_id, poll_timeout_in_seconds
    end

    def check_pid
      system "kill -0 #{@pid} 2> /dev/null"
    end

    def stop
      @running = false
    end

    def start
      @running = true
      Thread.new do
        while @running do
          if !check_pid
            @running = false
            UnitedWorkers::Queue.get(@queue_id).publish({type: :task_end, status: :killed, task: @task_id})
          end
          sleep @poll_timeout_in_seconds
        end
      end
    end
  end
end
