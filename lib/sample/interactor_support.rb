module InteractorSupport
  def async(target, &block)
    operation = InteractorOperation.alloc.initWithTarget(target)

    if block_given?
      handler = InteractorEventHandler.new(self, operation)
      handler.instance_eval(&block)

      @handlers ||= []
      @handlers << handler
    end

    InteractorOperationQueue.addOperation(operation)

    operation
  end
end
