#encoding: utf-8

require 'spec_helper'

describe UnitedWorkers::Worker do
  TASK_QUEUE = "tasks"
  WORK_QUEUE = "work"

  it "registers itself with the pending work queue" do
  end

  it "notifies the task queue that it has started" do
  end

  it "notifies the task queue that it has finished" do
  end

  it "executes the code block passed" do
    called = false
    UnitedWorkers::Worker.new(TASK_QUEUE, WORK_QUEUE) do
      called = true
    end
    expect(called).to be true
  end
end
