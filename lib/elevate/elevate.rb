module Elevate
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def task(name, options = {}, &block)
      task_definitions[name.to_sym] = TaskDefinition.new(name.to_sym, options, &block)
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
    raise ArgumentError, "args must be a Hash" unless args.is_a? Hash

    definition = self.class.task_definitions[name.to_sym]

    task = Task.new(definition, self, active_tasks)
    task.start(args)

    task
  end

  def task_args
    @__elevate_task_args
  end

  def task_args=(args)
    @__elevate_task_args = args
  end

  private

  def active_tasks
    @__elevate_active_tasks ||= []
  end
end
