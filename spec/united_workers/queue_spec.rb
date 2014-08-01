#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::Queue do
  before :each do
    queue = synchronous_queue
    channel = double(queue: queue).as_null_object
    allow(queue).to receive(:channel).and_return(channel)
    bunny = double(create_channel: channel, start: nil)
    allow(Bunny).to receive(:new).and_return(bunny)
  end

  describe '.subscribe / .publish' do
    it 'adds a listener to the queue' do

      called = false
      UnitedWorkers::Queue.subscribe(:queue) do |message|
        called = true
        expect(message).to be == 'hallo'
      end

      UnitedWorkers::Queue.publish(:queue, 'hallo')
    end
  end
end
