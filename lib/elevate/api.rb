module Elevate
  def async(input = {}, &block)
    with_operation(input, block) do |operation|
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

  def with_operation(input, dsl_block, &block)
    dsl = DSL.new(&dsl_block)

    operation = ElevateOperation.alloc.initWithTarget(dsl.task_callback, args: input)
    operation.on_started  = Callback.new(self, dsl.started_callback)  if dsl.started_callback
    operation.on_finished = Callback.new(self, dsl.finished_callback) if dsl.finished_callback

    yield operation

    operation
  end
end
