module Interactor
  module Support
    def async(target, &block)
      with_operation(target, block) do |operation|
        Dispatch.once do
          $interactor_queue = NSOperationQueue.alloc.init
          $interactor_queue.maxConcurrentOperationCount = 1
        end

        $interactor_queue.addOperation(operation)
      end
=begin
      operation = InteractorOperation.alloc.initWithTarget(target)

      if block_given?
        dsl = DSL.new(&block)

        operation.on_started  = Callback.new(self, operation, dsl.started_callback)  if dsl.started_callback
        operation.on_finished = Callback.new(self, operation, dsl.finished_callback) if dsl.finished_callback
      end

      interactor_queue.addOperation(operation)

      operation
=end
    end

    def sync(target, &block)
      with_operation(target, block) do |operation|
        operation.run()
      end
    end

  private

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
