class InteractorOperationQueue
  def self.addOperation(operation)
    queue.addOperation(operation)
  end

private

  def self.queue
    Dispatch.once do
      @queue = NSOperationQueue.alloc.init
      @queue.maxConcurrentOperationCount = 1
    end

    @queue
  end
end
