module Elevate
  def async(&block)
    with_operation(block) do |operation|
      queue.addOperation(operation)
    end
  end

  private

  def queue
    Dispatch.once do
      $elevate_queue = NSOperationQueue.alloc.init
      $elevate_queue.maxConcurrentOperationCount = 1
    end

    $elevate_queue
  end

  def with_operation(dsl_block, &block)
    dsl = DSL.new(&dsl_block)

    operation = ElevateOperation.alloc.initWithTarget(dsl.task_callback, context: self)
    operation.on_started  = dsl.started_callback  if dsl.started_callback
    operation.on_finished = dsl.finished_callback if dsl.finished_callback

    yield operation

    operation
  end
end
