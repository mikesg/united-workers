class UnitedWorkers::Interceptor
  def initialize(external_queue, internal_queue, &coroutine)
    @external_queue = external_queue
    @internal_queue = internal_queue
    @coroutine = coroutine
  end

  #.start will block the current thread and wait for messages.
  def self.start(external_queue, internal_queue, &coroutine)
    worker = self.new(external_queue, internal_queue, &coroutine)
    worker.setup_subscriptions
    worker
  end

  def setup_subscriptions
    @queue = UnitedWorkers::Queue.get(@external_queue)
    @queue.subscribe(ack: true, block: true) { |delivery_info, properties, body|
      tasks = @coroutine.call(body)
      internal_queue = UnitedWorkers::Queue.get(@internal_queue)
      tasks.each { |task_id, params| internal_queue.publish({task_id: task_id, params: params}, persistent: true)}
      acknowledge delivery_info
    }
  end

  def acknowledge(delivery_info)
    @queue.channel.ack(delivery_info.delivery_tag)
  end
end
