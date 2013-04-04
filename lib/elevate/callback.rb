module Elevate
  class Callback
    def initialize(context, operation, block)
      @context = context
      @operation = operation
      @block = block
    end

    def call
      unless NSThread.isMainThread
        self.performSelectorOnMainThread(:call, withObject: self, waitUntilDone: true)
        return
      end

      @context.instance_exec(@operation, &@block)
    end
  end
end
