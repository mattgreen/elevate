module Elevate
  class Callback
    def initialize(controller, block)
      @controller = controller
      @block = block
    end

    def call(*args)
      if NSThread.isMainThread
        invoke(*args)
      else
        Dispatch::Queue.main.sync { invoke(*args) }
      end
    end

    private

    def invoke(*args)
      @controller.instance_exec(*args, &@block)
    end
  end
end
