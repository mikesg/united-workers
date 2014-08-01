#encoding: utf-8
require 'bunny'
require 'yaml'

module UnitedWorkers
  class Queue
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
