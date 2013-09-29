module Elevate
  class Task
    def initialize(controller, active_tasks, handlers)
      @controller = WeakRef.new(controller)
      @active_tasks = active_tasks
      @operation = nil
      @channel = Channel.new(method(:on_update))
      @handlers = handlers
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
      raise "invalid argument count" if args.length != @handlers[:body].arity

      @operation = ElevateOperation.alloc.initWithTarget(@handlers[:body],
                                                         args: args,
                                                         channel: WeakRef.new(@channel))

      @operation.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptionNew, context: nil)
      queue.addOperation(@operation)
      @active_tasks << self

      performSelectorOnMainThread(:on_start, withObject: nil, waitUntilDone: false)
    end

    private

    def invoke(block, *args)
      return unless block

      @controller.instance_exec(*args, &block)
    end

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
      invoke(@handlers[:on_start])
    end

    def on_finish
      operation = @operation

      @operation.removeObserver(self, forKeyPath: "isFinished")
      @operation = nil

      @active_tasks.delete(self)

      if exception = operation.exception
        invoke(@handlers[:on_error], exception)
      end

      invoke(@handlers[:on_finish], operation.result, operation.exception)
    end

    def on_update(args)
      unless NSThread.isMainThread
        performSelectorOnMainThread(:"on_update:", withObject: args, waitUntilDone: false)
        return
      end

      invoke(@handlers[:on_update], *args)
    end
  end
end
