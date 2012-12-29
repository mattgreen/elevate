module Interactor
  module Support
    def async(target, &block)
      with_operation(target, block) do |operation|
        queue.addOperation(operation)
      end
    end

  private

    def queue
      Dispatch.once do
        $interactor_queue = NSOperationQueue.alloc.init
        $interactor_queue.maxConcurrentOperationCount = 1
      end

      $interactor_queue
    end

    def with_operation(target, dsl_block, &block)
      operation = InteractorOperation.alloc.initWithTarget(target)

      if dsl_block
        dsl = DSL.new(&dsl_block)

        operation.on_started  = Callback.new(self, operation, dsl.started_callback)  if dsl.started_callback
        operation.on_finished = Callback.new(self, operation, dsl.finished_callback) if dsl.finished_callback
      end

      yield operation

      operation
    end
  end
end
