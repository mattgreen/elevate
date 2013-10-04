module Elevate
  class Task
    def initialize(definition, controller, active_tasks)
      @definition = definition
      @controller = WeakRef.new(controller)
      @active_tasks = active_tasks
      @operation = nil
      @channel = Channel.new(method(:on_update))
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
      raise "invalid argument count" if args.length != handlers[:body].arity

      @operation = ElevateOperation.alloc.initWithTarget(handlers[:body],
                                                         args: args,
                                                         channel: WeakRef.new(@channel))

      @operation.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptionNew, context: nil)
      queue.addOperation(@operation)
      @active_tasks << self

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

    def handlers
      @definition.handlers
    end

    def invoke(block, *args)
      return if @operation.cancelled?
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
      invoke(handlers[:on_start])
    end

    def on_finish
      @operation.removeObserver(self, forKeyPath: "isFinished")
      @active_tasks.delete(self)

      if @timer
        @timer.invalidate
      end

      if exception = @operation.exception
        invoke(handlers.fetch(error_handler_for(exception), handlers[:on_error]), exception)
      end

      invoke(handlers[:on_finish], @operation.result, @operation.exception)
    end

    def on_timeout(timer)
      @operation.timeout
    end

    def on_update(args)
      unless NSThread.isMainThread
        performSelectorOnMainThread(:"on_update:", withObject: args, waitUntilDone: false)
        return
      end

      invoke(handlers[:on_update], *args)
    end
  end
end
