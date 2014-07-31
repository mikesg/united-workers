#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::WorkerSpawner do
  before :each do
    UnitedWorkers::WorkerSpawner.launch_strategy = :thread
    allow(UnitedWorkers::Queue).to receive(:new_fanout_queue).and_return(synchronous_queue)
  end

  describe '.start' do
    it 'launches processes based on bootstrap and instance count' do
      called = 0
      bootstrap = lambda { called += 1 }

      UnitedWorkers::WorkerSpawner.start(bootstrap, 10, :monitor)
      sleep(0.1)
      expect(called).to be 10
    end
  end
end
