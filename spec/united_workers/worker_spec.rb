#encoding: utf-8

require 'spec_helper'
require 'queue_helper'

describe UnitedWorkers::Worker do
  it "registers itself with the pending work queue" do
    expect(UnitedWorkers::Queue).to receive(:subscribe).with(:work, true)

    UnitedWorkers::Worker.new(:work, :monitor, ->(task_id, params) {}, ->() {})
  end
end
