#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::Worker do
  it "registers itself with the pending work queue" do
    work_queue = double
    allow(UnitedWorkers::Queue).to receive(:get).with(:work).and_return work_queue

    expect(work_queue).to receive(:subscribe)

    UnitedWorkers::Worker.new(:work, :monitor, ->(task_id, params) {}, ->() {})
  end

  context 'monitor queue notifications' do
    before :each do
      work_queue = synchronous_queue
      allow(UnitedWorkers::Queue).to receive(:get).with(:work).and_return work_queue
      monitor_queue = synchronous_queue
      allow(UnitedWorkers::Queue).to receive(:new_fanout_queue).with(:monitor).and_return monitor_queue
      allow(UnitedWorkers::Queue).to receive(:fanout_publish) { |ch, msg| monitor_queue.publish(msg) }

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
      result = double
      def result.error?
        false
      end

      def result.payload
        "A Laptop structure"
      end

      UnitedWorkers::Worker.new(:work, :monitor, ->(msg) { result }, ->(_,_,_) {} )
      @target, @work_queue, @monitor_queue = target, work_queue, monitor_queue
    end

    it "notifies the monitor queue that it has started" do
      statuses = []
      expect(@target).to receive(:called).twice do |msg|
        expect(msg[:task_id]).to eq 'task1'
        statuses << msg[:type]
      end
      @work_queue.publish({task_id: 'task1', params: {}}, persistent: true)
      expect(statuses).to include(:start_monitor)
    end

    it "notifies the monitor queue that it has finished" do
      statuses = []
      expect(@target).to receive(:called).twice do |msg|
        expect(msg[:task_id]).to eq 'task1'
        statuses << msg[:type]
      end
      @work_queue.publish({task_id: 'task1', params: {}}, persistent: true)
      expect(statuses).to include(:stop_monitor)
    end


    it "executes the code block passed" do
      coroutine = double
      expect(coroutine).to receive(:called)
      result = double(:error? => false)
      UnitedWorkers::Worker.new(:work, :monitor, ->(msg) { coroutine.called; result }, ->(_,_,_) {})
      @work_queue.publish({task_id: 'task1', params: {}}, persistent: true)
    end
  end
end
