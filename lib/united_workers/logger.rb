#encoding: utf-8

module UnitedWorkers
  class Logger
    def self.log(message)
      File.open('log/workers.log', 'a') { |f| f.puts message }
    end
  end
end
