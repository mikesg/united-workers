#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::Monitor do
  before :each do
    load 'lib/united_workers/monitor.rb'
  end

  describe 'Messages' do
    before :each do
      queue = synchronous_queue
      allow(UnitedWorkers::Queue).to receive(:get).with(:monitor).and_return(queue)
      UnitedWorkers::Monitor.launch(:monitor)
    end

    context "starting a monitor" do
      it 'publishes a message on the monitor queue' do
        called = false
        UnitedWorkers::Queue.get(:monitor).subscribe do |_, __, message|
          called = true
          expect(message[:type]).to be :start_monitor
          expect(message[:pid]).to be :a_pid
          expect(message[:task_id]).to be :task123
        end

        UnitedWorkers::Monitor.start_monitor(:a_pid, :task123)

        expect(called).to be true
      end

      it 'starts a new monitor thread' do
        expect(UnitedWorkers::Monitor::MonitorThread).to receive(:new).and_call_original

        UnitedWorkers::Monitor.start_monitor(:a_pid, :task123)
      end
    end

    context 'stopping a monitor' do
      it 'calls stop of the thread' do
        expect_any_instance_of(UnitedWorkers::Monitor::MonitorThread).to receive(:stop)
        UnitedWorkers::Monitor.start_monitor(:a_pid, :task123)

        UnitedWorkers::Monitor.stop_monitor(:task123)
      end
    end
  end

  describe '.launch' do
    it 'raises if called twice' do
      expect(UnitedWorkers::Queue).to receive(:get).with(:monitor).and_return(synchronous_queue)
      UnitedWorkers::Monitor.launch(:monitor)
      expect { UnitedWorkers::Monitor.launch(:monitor) }.to raise_error
    end

    it 'subcscribes to the monitor queue' do
      queue = double
      expect(UnitedWorkers::Queue).to receive(:get).with(:monitor).and_return(queue)
      expect(queue).to receive(:subscribe)
      UnitedWorkers::Monitor.launch(:monitor)
    end
  end
end
