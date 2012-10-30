class InteractorEventHandler
  def initialize(context, operation)
    @context      = context
    @operation    = operation

    @on_completed = default_handler
    @on_started   = default_handler

    start_observing()

    invoke_callback(:on_started, @context)
  end

  def on_completed(&block)
    @on_completed = block || default_handler
  end

  def on_started(&block)
    @on_started = block || default_handler
  end

private

  def default_handler
    @@default_handler ||= lambda { |operation| }
  end

  def invoke_callback(callback, context)
    Dispatch::Queue.main.async do
      unless @operation.isCancelled
        handler = instance_variable_get("@#{callback.to_s}")

        context.instance_exec(@operation, &handler)
      end
    end
  end

  def observeValueForKeyPath(keyPath, ofObject:operation, change:change, context:context)
    return unless change[NSKeyValueChangeNewKey] > 0

    if keyPath == "isFinished"
      invoke_callback(:on_completed, @context)
    end

    if operation.isFinished || operation.isCancelled
      stop_observing()
   end
  end

  def start_observing
    @operation.addObserver(self, forKeyPath: "isCancelled", options: NSKeyValueObservingOptionNew, context: nil)
    @operation.addObserver(self, forKeyPath: "isFinished",  options: NSKeyValueObservingOptionNew, context: nil)
  end

  def stop_observing
    @operation.removeObserver(self, forKeyPath: "isCancelled")
    @operation.removeObserver(self, forKeyPath: "isFinished")

    # Context must be released in main thread, if it is a UIViewController.
    Dispatch::Queue.main.async do
      @context = nil
    end
   end
end
