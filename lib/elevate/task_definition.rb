module Elevate
  class TaskDefinition
    def initialize(options, &block)
      @handlers = {}
      @options = options

      instance_eval(&block)
    end

    attr_reader :handlers
    attr_reader :options

    def on_error(&block)
      raise "on_error blocks must accept one parameter" unless block.arity == 1

      @handlers[:on_error] = block
    end

    def on_finish(&block)
      raise "on_finish blocks must accept two parameters" unless block.arity == 2

      @handlers[:on_finish] = block
    end

    def on_start(&block)
      raise "on_start blocks must accept zero parameters" unless block.arity == 0

      @handlers[:on_start] = block
    end

    def on_timeout(&block)
      raise "on_timeout blocks must accept zero parameters" unless block.arity == 0

      @handlers[:on_timeout] = block
    end

    def on_update(&block)
      @handlers[:on_update] = block
    end

    def task(&block)
      @handlers[:body] = block
    end

    def timeout(seconds)
      raise "timeout argument must be a number" unless seconds.is_a?(Numeric)

      @options[:timeout_interval] = seconds
    end
  end
end
