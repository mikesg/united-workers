class UnitedWorkers::Worker
  def initialize(work_queue, monitor_queue, message_routine, success_routine)
    @work_queue = work_queue
    @monitor_queue = monitor_queue
    @message_routine = message_routine
    @success_routine = success_routine
    UnitedWorkers::Queue.subscribe(work_queue, true) do |message|
      UnitedWorkers::Logger.log("Worker received message:#{message}")
      process(message)
      UnitedWorkers::Logger.log("Worker processed message:#{message}")
    end
  end

  def process(message)
    UnitedWorkers::Monitor.start_monitor(@monitor_queue, Process.pid, message[:task_id])
    result = @message_routine.call(message)
    if result.error?
      UnitedWorkers::Queue.fanout_publish(@monitor_queue, {type: :task_end, status: :error, task_id: message[:task_id]})
    else
      @success_routine.call(@monitor_queue, message, result)
    end
    UnitedWorkers::Monitor.stop_monitor(@monitor_queue, message[:task_id])
  end

  def report_success(monitor_queue, message, result)
    UnitedWorkers::Queue.fanout_publish(monitor_queue, {type: :task_end, status: :ok, task_id: message[:task_id]})
  end

      #save the result to a temp file
      #UnitedWorkers::Queue.get(@next_queue).publish(company, product, file handle, task ID)
end
