#encoding: utf-8
require 'bunny'
require 'yaml'

module UnitedWorkers
  class Queue
    def self.subscribe(queue_identifier, block_thread = false)
      raise "usage: subscribe(queue_id) { |message| ... }" if !block_given?
      queue = channel.queue(queue_identifier, durable: true)
      queue.channel.prefetch(1)
      queue.subscribe(ack: true, block: block_thread) do |delivery_info, properties, message|
        queue.channel.ack(delivery_info.delivery_tag)
        yield unpack(message)
      end
    end

    def self.publish(queue_identifier, message)
      queue = channel.queue(queue_identifier, durable: true)
      queue.publish(pack(message), persistent: true)
      queue.channel.tap do |ch|
        ch.close
        ch.connection.close
      end
    end

    def self.new_fanout_queue(channel_id)
      ch = channel
      x = ch.fanout(channel_id)
      q = ch.queue("", exclusive: true)
      q.bind(x)
      q
    end

    def self.fanout_publish(channel_id, message)
      ch = channel
      x = ch.fanout(channel_id)
      x.publish(pack(message))
      ch.close
      ch.connection.close
    end

    def self.channel
      conn = Bunny.new
      conn.start
      conn.create_channel
    end

    def self.pack(message)
      if message.is_a?(String)
        message
      else
        message.to_yaml
      end
    end

    def self.unpack(message)
      if message.is_a?(String)
        YAML.load(message)
      else
        message
      end
    end
  end
end
