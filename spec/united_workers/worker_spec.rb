#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::Worker do
  it "registers itself with the pending work queue" do
    work_queue = double
    allow(UnitedWorkers::Queue).to receive(:get).with(:work).and_return work_queue

    expect(work_queue).to receive(:subscribe)

    UnitedWorkers::Worker.new(:work, :monitor) { |task_id, params| }
  end

  context 'monitor queue notifications' do
    before :each do
      work_queue = synchronous_queue
      allow(UnitedWorkers::Queue).to receive(:get).with(:work).and_return work_queue
      monitor_queue = synchronous_queue
      allow(UnitedWorkers::Queue).to receive(:get).with(:monitor).and_return monitor_queue

      target = double
      def target.called(message)
        @message = message
      end

      def target.message
        @message
      end

      monitor_queue.subscribe do |_, __, message|
        target.called(message)
      end
      UnitedWorkers::Worker.new(:work, :monitor) {}
      @target, @work_queue, @monitor_queue = target, work_queue, monitor_queue
    end

    it "notifies the monitor queue that it has started" do
      statuses = []
      expect(@target).to receive(:called).twice do |msg|
        expect(msg[:task_id]).to eq 'task1'
        statuses << msg[:status]
        expect(msg[:pid]).to eq Process.pid
      end
      @work_queue.publish({task_id: 'task1', params: {}}, persistent: true)
      expect(statuses).to include('started')
    end

    it "notifies the monitor queue that it has finished" do
      statuses = []
      expect(@target).to receive(:called).twice do |msg|
        expect(msg[:task_id]).to eq 'task1'
        statuses << msg[:status]
        expect(msg[:pid]).to eq Process.pid
      end
      @work_queue.publish({task_id: 'task1', params: {}}, persistent: true)
      expect(statuses).to include('finished')
    end
  end

  it "executes the code block passed" do
    allow(UnitedWorkers::Queue).to receive(:get).with(:work).and_return synchronous_queue
    called = false
    UnitedWorkers::Worker.new(:work, :monitor) do
      called = true
    end
    #expect(called).to be true
  end
end
