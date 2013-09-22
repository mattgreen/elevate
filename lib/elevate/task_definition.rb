module Elevate
  class TaskDefinition
    def initialize(options, &block)
      @options = options

      instance_eval(&block)
    end

    attr_reader :options
    attr_reader :finish_callback
    attr_reader :start_callback
    attr_reader :task_callback
    attr_reader :update_callback

    attr_reader :timeout_callback
    attr_reader :timeout_interval

    def on_finish(&block)
      raise "on_finish blocks must accept two parameters" unless block.arity == 2

      @finish_callback = block
    end

    def on_start(&block)
      raise "on_start blocks must accept zero parameters" unless block.arity == 0

      @start_callback = block
    end

    def on_timeout(&block)
      raise "on_timeout blocks must accept zero parameters" unless block.arity == 0

      @timeout_callback = block
    end

    def on_update(&block)
      @update_callback = block
    end

    def task(&block)
      raise "task blocks must accept zero parameters" unless block.arity == 0

      @task_callback = block
    end

    def timeout(seconds)
      raise "timeout argument must be a number" unless seconds.is_a?(Numeric)

      @timeout_interval = seconds
    end
  end
end
