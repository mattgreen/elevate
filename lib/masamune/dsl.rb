module Masamune
  class DSL
    def initialize(&block)
      instance_eval(&block)
    end

    attr_reader :started_callback
    attr_reader :finished_callback

    def on_started(&block)
      @started_callback = block
    end

    def on_completed(&block)
      @finished_callback = block
    end
  end
end
