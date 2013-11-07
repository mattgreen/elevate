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
    def initWithTarget(target, args: args, channel: channel)
      if init
        @coordinator = IOCoordinator.new
        @context = TaskContext.new(target, channel, args)
        @exception = nil
        @result = nil
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

    # Runs the specified task.
    #
    # @return [void]
    #
    # @api private
    def main
      @coordinator.install

      begin
        unless @coordinator.cancelled?
          @result = @context.execute
        end

      rescue => e
        @exception = e
      end

      @coordinator.uninstall

      @context = nil
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

    # Cancels any waiting operation with a TimeoutError, interrupting
    # execution. This is not the same as #cancel.
    #
    # @return [void]
    #
    # @api public
    def timeout
      @coordinator.cancel(TimeoutError)
    end
  end
end
