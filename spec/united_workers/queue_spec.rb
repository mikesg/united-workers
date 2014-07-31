#encoding: utf-8

require 'spec_helper'

describe UnitedWorkers::Queue do
  def rabbit(queue)
    conn = double
    channel = double
  end

  before :each do
  end


  describe '.get' do
    it 'creates a queue based on config' do
      queue = double
      allow(Bunny).to receive(:new).and_return rabbit(queue)
    end
  end
end
