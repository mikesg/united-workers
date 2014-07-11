class UnitedWorkers::Worker
  def initialize(work_queue, monitor_queue, &coroutine)
    @work_queue = work_queue
    @monitor_queue = monitor_queue
    @coroutine = coroutine
    @queue = UnitedWorkers::Queue.get(work_queue)
    @queue.subscribe(ack: true, block: true) do |delivery_info, properties, message|
      @queue.channel.ack(delivery_info.delivery_tag)
      process(message)
    end
  end

  def process(message)
    UnitedWorkers::Queue.get(@monitor_queue).publish({task_id: message[:task_id], pid: Process.pid, status: 'started'}, persistent: true)

    UnitedWorkers::Queue.get(@monitor_queue).publish({task_id: message[:task_id], pid: Process.pid, status: 'finished'}, persistent: true)
  end
end
