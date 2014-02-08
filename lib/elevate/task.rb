module Elevate
  class Task
    def initialize(definition, controller, active_tasks)
      @definition = definition
      @controller = WeakRef.new(controller)
      @active_tasks = active_tasks
      @operation = nil
      @channel = Channel.new(method(:on_update))
      @args = nil
      @timer = nil
    end

    def cancel
      if @operation
        @operation.cancel

        if @timer
          @timer.invalidate
        end
      end
    end

    def name
      @definition.name
    end

    def start(args)
      @operation = ElevateOperation.alloc.initWithTarget(@definition.handlers[:background],
                                                         args: args,
                                                         channel: WeakRef.new(@channel))

      @operation.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptionNew, context: nil)
      queue.addOperation(@operation)
      @active_tasks << self

      @args = args

      if interval = @definition.options[:timeout_interval]
        @timer = NSTimer.scheduledTimerWithTimeInterval(interval,
                                                        target: self,
                                                        selector: :"on_timeout:",
                                                        userInfo: nil,
                                                        repeats: false)
      end

      performSelectorOnMainThread(:on_start, withObject: nil, waitUntilDone: false)
    end

    private

    def error_handler_for(exception)
      handler_name = exception.class.name
      handler_name = handler_name.split("::").last
      handler_name.gsub!(/Error$/, "")
      handler_name.gsub!(/(.)([A-Z])/) { |m| "#{$1}_#{$2.downcase}" }
      handler_name = "on_" + handler_name.downcase

      handler_name.to_sym
    end

    def invoke(handler_name, *args)
      return false if @operation.isCancelled

      block = @definition.handlers[handler_name]
      return false unless block

      @controller.task_args = @args
      @controller.instance_exec(*args, &block)
      @controller.task_args = nil

      true
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
      invoke(:on_start)
    end

    def on_finish
      p "on_finish"

      @operation.removeObserver(self, forKeyPath: "isFinished")
      @active_tasks.delete(self)

      if @timer
        @timer.invalidate
      end

      if exception = @operation.exception
        invoke(error_handler_for(exception), exception) || invoke(:on_error, exception)
      end

      invoke(:on_finish, @operation.result, @operation.exception)
    end

    def on_timeout(timer)
      p "on_timeout"

      @operation.timeout
    end

    def on_update(args)
      unless NSThread.isMainThread
        performSelectorOnMainThread(:"on_update:", withObject: args, waitUntilDone: false)
        return
      end

      invoke(:on_update, *args)
    end
  end
end
