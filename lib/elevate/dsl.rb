module Elevate
  class DSL
    def initialize(&block)
      instance_eval(&block)
    end

    attr_reader :finish_callback
    attr_reader :start_callback
    attr_reader :task_callback
    attr_reader :update_callback

    def on_finish(&block)
      raise "on_finish blocks must accept two parameters" unless block.arity == 2

      @finish_callback = block
    end

    def on_start(&block)
      raise "on_start blocks must accept zero parameters" unless block.arity == 0

      @start_callback = block
    end

    def on_update(&block)
      @update_callback = block
    end

    def task(&block)
      raise "task blocks must accept zero parameters" unless block.arity == 0

      @task_callback = block
    end
  end
end
