module Elevate
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def task(name, options = {}, &block)
      task_definitions[name.to_sym] = TaskDefinition.new(options, &block)
    end

    def task_definitions
      @task_definitions ||= {}
    end
  end

  def cancel(name)
    active_tasks.each do |task|
      if task.name == name
        task.cancel
      end
    end
  end

  def cancel_all
    active_tasks.each do |task|
      task.cancel
    end
  end

  def launch(name, args = {})
    definition = self.class.task_definitions[name.to_sym]

    task = Task.new(self, active_tasks, definition.task_callback)
    task.on_start = definition.start_callback
    task.on_finish = definition.finish_callback
    task.on_update = definition.update_callback
    task.start(args)

    task
  end

  private

  def active_tasks
    @__active_tasks ||= []
  end
end
