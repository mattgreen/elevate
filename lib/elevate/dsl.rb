module Elevate
  class DSL
    def initialize(&block)
      instance_eval(&block)
    end

    attr_reader :started_callback
    attr_reader :finished_callback
    attr_reader :task_callback

    def task(&block)
      raise "task blocks must accept zero parameters" unless block.arity == 0

      @task_callback = block
    end

    def on_started(&block)
      raise "on_started blocks must accept zero parameters" unless block.arity == 0

      @started_callback = block
    end

    def on_completed(&block)
      raise "on_completed blocks must accept two parameters" unless block.arity == 2

      @finished_callback = block
    end
  end
end
