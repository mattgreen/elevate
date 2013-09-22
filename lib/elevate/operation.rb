module Elevate
  # Executes an Elevate task, firing callbacks along the way.
  #
  class ElevateOperation < NSOperation
    # Designated initializer.
    #
    # @return [ElevateOperation]
    #   newly initialized instance
    #
    # @api private
    def initWithTarget(target, args: args, update: update_callback)
      if init
        @coordinator = IOCoordinator.new
        @context = TaskContext.new(target, args)
        @update_callback = update_callback
      end

      self
    end

    # Cancels the currently running task.
    #
    # @return [void]
    #
    # @api public
    def cancel
      @coordinator.cancel

      super
    end

    def invoke_update_callback(args)
      unless NSThread.isMainThread
        performSelectorOnMainThread(:"invoke_update_callback:", withObject: args, waitUntilDone: true)
        return
      end

      @update_callback.call(*args)
    end

    # Runs the specified task.
    #
    # @return [void]
    #
    # @api private
    def main
      @coordinator.install

      begin
        unless @coordinator.cancelled?
          @result = @context.execute do |*args|
            invoke_update_callback(args) if @update_callback
          end
        end

      rescue Exception => e
        @exception = e
      end

      @coordinator.uninstall

      @context = nil
      @update_callback = nil
    end

    # Returns the exception that terminated this task, if any.
    #
    # If the task has not finished, returns nil.
    #
    # @return [Exception, nil]
    #   exception that terminated the task
    #
    # @api public
    attr_reader :exception

    # Returns the result of the task block.
    #
    # If the task has not finished, returns nil.
    #
    # @return [Object, nil]
    #   result of the task block
    #
    # @api public
    attr_reader :result
  end
end
