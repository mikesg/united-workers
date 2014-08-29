#encoding: utf-8

class UnitedWorkers::ProcessResult
  attr_reader :payload
  def initialize(error, payload)
    @error, @payload = error, payload
  end

  def error?
    @error
  end
end
