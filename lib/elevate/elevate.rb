module Elevate
  # Launches a new asynchronous task.
  #
  # @param args [Hash]
  #   input arguments for the task, available to the +task+ block
  #
  # @return [NSOperation]
  #   operation representing this task
  #
  # @api public
  def async(args = {}, &block)
    with_operation(args, block) do |operation|
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

  def with_operation(args, dsl_block, &block)
    dsl = DSL.new(&dsl_block)

    raise "No task block specified!" unless dsl.task_callback

    operation = ElevateOperation.alloc.initWithTarget(dsl.task_callback, args: args)
    weak = WeakRef.new(self)

    operation.on_start  = Callback.new(weak, dsl.start_callback)  if dsl.start_callback
    operation.on_finish = Callback.new(weak, dsl.finish_callback) if dsl.finish_callback
    operation.on_update = Callback.new(weak, dsl.update_callback)   if dsl.update_callback
    operation.on_timeout= Callback.new(weak, dsl.timeout_callback)  if dsl.timeout_callback

    operation.timeout = dsl.timeout_interval if dsl.timeout_interval

    yield operation

    operation
  end
end
