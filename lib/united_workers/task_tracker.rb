#encoding: utf-8

class UnitedWorkers::TaskTracker
  def initialize
    @tasks = []
    @mutex = Mutex.new
  end

  def add(o)
    @mutex.synchronize do
      @tasks << o
    end
  end

  def completed(task_id)
    completed_groups = []
    @mutex.synchronize do
      @tasks.each do |task_list, product, country|
        task_list.delete(task_id)
        if task_list.empty?
          completed_groups << [product, country]
        end
      end
      @tasks.delete_if { |task_list, _, _| task_list.empty? }
    end
    completed_groups
  end
end
