#encoding: utf-8

class UnitedWorkers::Monitor
  @launched = false
  attr_reader :channel_id

  #This is intended to be run within the job dispatcher and live together with it. Monitor threads will belong to main dispatchec process
  def self.launch(channel_id)
    raise 'Already runnung' if @launched
    @launched = true
    @instance = UnitedWorkers::Monitor.new(channel_id)
  end

  def self.instance
    @instance
  end

  def initialize(channel_id)
    @channel_id = channel_id
    @running_tasks = {}
    @task_mutex = Mutex.new

    UnitedWorkers::Queue.new_fanout_queue(channel_id).subscribe do |delivery_info, properties, message|
      message = UnitedWorkers::Queue.unpack(message)
      if message[:type] && [:start_monitor, :stop_monitor].include?(message[:type].to_sym)
        monitor_message(message[:type].to_sym, message[:pid], message[:task_id])
      end
    end
  end

  def self.start_monitor(channel_id, pid, task_id)
    UnitedWorkers::Logger.log 'start'
    UnitedWorkers::Queue.fanout_publish(channel_id, {type: :start_monitor, pid: pid, task_id: task_id})
  end

  def self.stop_monitor(channel_id, task_id)
    UnitedWorkers::Queue.fanout_publish(channel_id, {type: :stop_monitor, task_id: task_id})
  end

  private
  def monitor_message(type, pid, task_id)
    @task_mutex.synchronize do
      if type == :start_monitor
        thread = MonitorThread.new(channel_id, pid, task_id)
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
    def initialize(channel_id, pid, task_id, poll_timeout_in_seconds = 2)
      @channel_id, @pid, @task_id, @poll_timeout_in_seconds = channel_id, pid, task_id, poll_timeout_in_seconds
    end

    def check_pid
      system "kill -0 #{@pid} 2> /dev/null"
    end

    def stop
      @running = false
    end

    def start
      UnitedWorkers::Logger.log "Start monitor thread on #{@pid}/#{@task_id}"
      @running = true
      Thread.new do
        while @running do
          #UnitedWorkers::Logger.log "polling"
          if !check_pid
            @running = false
            UnitedWorkers::Queue.fanout_publish(@channel_id, {type: :task_end, status: :killed, task_id: @task_id, pid: @pid})
            UnitedWorkers::Logger.log "Stopping monitor thread on #{@pid}/#{@task_id} - process not alive"
          end
          sleep @poll_timeout_in_seconds
        end
      end
    end
  end
end
