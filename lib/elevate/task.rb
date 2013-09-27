module Elevate
  class Task
    def initialize(controller, active_tasks, body)
      @controller = WeakRef.new(controller)
      @active_tasks = active_tasks
      @operation = nil
      @channel = Channel.new(method(:on_update))
      @handlers = { body: body }
    end

    def cancel
      if @operation
        @operation.cancel
      end
    end

    def on_finish=(block)
      @handlers[:on_finish] = block
    end

    def on_start=(block)
      @handlers[:on_start] = block
    end

    def on_update=(block)
      @handlers[:on_update] = block
    end

    def start(args)
      @operation = ElevateOperation.alloc.initWithTarget(@handlers[:body], args: args, channel: @channel)

      @operation.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptionNew, context: nil)
      queue.addOperation(@operation)
      @active_tasks << self

      performSelectorOnMainThread(:on_start, withObject: nil, waitUntilDone: false)
    end

    private

    def queue
      Dispatch.once do
        $elevate_queue = NSOperationQueue.alloc.init
        $elevate_queue.maxConcurrentOperationCount = 1
      end

      $elevate_queue
    end

    def observeValueForKeyPath(path, ofObject: operation, change: change, context: ctx)
      case path
      when "isFinished"
        performSelectorOnMainThread(:on_finish, withObject: nil, waitUntilDone: false)
      end
    end

    def on_start
      if handler = @handlers[:on_start]
        @controller.instance_eval(&handler)
      end
    end

    def on_finish
      operation = @operation

      @operation.removeObserver(self, forKeyPath: "isFinished")
      @operation = nil

      @active_tasks.delete(self)

      if handler = @handlers[:on_finish]
        @controller.instance_exec(operation.result, operation.exception, &handler)
      end
    end

    def on_update(args)
      unless NSThread.isMainThread
        performSelectorOnMainThread(:"on_update:", withObject: args, waitUntilDone: false)
        return
      end

      if handler = @handlers[:on_update]
        @controller.instance_exec(*args, &handler)
      end
    end
  end
end
