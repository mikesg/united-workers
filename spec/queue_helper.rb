#encodingL utf-8

def synchronous_queue
  queue = double
  def queue.subscribe(*args, &block)
    @block = block
  end
  def queue.publish(message, params = {})
    @block.call(delivery_info, nil, message)
  end
  allow(queue).to receive(:delivery_info).and_return(double.as_null_object)
  allow(queue).to receive(:channel).and_return(double.as_null_object)
  queue
end
