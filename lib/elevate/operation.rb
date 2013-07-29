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
    def initWithTarget(target, args:args)
      if init
        @coordinator = IOCoordinator.new
        @context = TaskContext.new(args, &target)
        @timeout_callback = nil
        @timer = nil
        @update_callback = nil
        @finish_callback = nil

        weak = WeakRef.new(self)
        setCompletionBlock(->{
          if weak
            weak.performSelectorOnMainThread(:finalize, withObject: nil, waitUntilDone: true)
            weak.setCompletionBlock(nil)
          end
        })
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

    # Releases resources used by this instance.
    #
    # @return [void]
    #
    # @api private
    def finalize
      if @finish_callback
        @finish_callback.call(@result, @exception) unless isCancelled
      end

      @context = nil

      if @timer
        @timer.invalidate
        @timer = nil
      end

      @timeout_callback = nil
      @update_callback = nil
      @finish_callback = nil
    end

    # Returns information about this task.
    #
    # @return [String]
    #   String suitable for debugging purposes.
    #
    # @api public
    def inspect
      details = []
      details << "<canceled>" if @coordinator.cancelled?

      "#<#{self.class.name}: #{details.join(" ")}>"
    end

    # Logs debugging information in certain configurations.
    #
    # @return [void]
    #
    # @api private
    def log(line)
      puts line unless RUBYMOTION_ENV == "test"
    end

    # Runs the specified task.
    #
    # @return [void]
    #
    # @api private
    def main
      log " START: #{inspect}"

      @coordinator.install

      begin
        unless @coordinator.cancelled?
          @result = @context.execute do |*args|
            @update_callback.call(*args) if @update_callback
          end
        end

      rescue Exception => e
        @exception = e

        if e.is_a?(TimeoutError)
          @timeout_callback.call if @timeout_callback
        end
      end

      @coordinator.uninstall

      log "FINISH: #{inspect}"
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

    # Sets the callback to be run upon completion of this task. Do not call
    # this method after the task has started.
    #
    # @param callback [Elevate::Callback]
    #   completion callback
    #
    # @return [void]
    #
    # @api private
    def on_finish=(callback)
      @finish_callback = callback
    end

    # Sets the callback to be run when this task is queued.
    #
    # Do not call this method after the task has started.
    #
    # @param callback [Elevate::Callback]
    #   callback to be invoked when queueing
    #
    # @return [void]
    #
    # @api private
    def on_start=(callback)
      weak = WeakRef.new(self)

      Dispatch::Queue.main.async do
        if weak
          callback.call unless weak.isCancelled
        end
      end
    end

    # Handles timeout expiration.
    #
    # @return [void]
    #
    # @api private
    def on_timeout_elapsed(timer)
      @coordinator.cancel(TimeoutError)
    end

    # Sets the timeout callback.
    #
    # @param callback [Elevate::Callback]
    #   callback to run on timeout
    #
    # @return [void]
    #
    # @api private
    def on_timeout=(callback)
      @timeout_callback = callback
    end

    # Sets the update callback, which is invoked for any yield statements in the task.
    #
    # @param callback [Elevate::Callback]
    # @return [void]
    #
    # @api private
    def on_update=(callback)
      @update_callback = callback
    end

    # Sets the timeout interval for this task.
    #
    # The timeout starts when the task is queued, not when it is started.
    #
    # @param interval [Fixnum]
    #   seconds to allow for task completion
    #
    # @return [void]
    #
    # @api private
    def timeout=(interval)
      @timer = NSTimer.scheduledTimerWithTimeInterval(interval,
                                                      target: self,
                                                      selector: :"on_timeout_elapsed:",
                                                      userInfo: nil,
                                                      repeats: false)
    end

    # Returns whether this task timed out.
    #
    # @return [Boolean]
    #   true if this task was aborted due to a time out.
    #
    # @api public
    def timed_out?
      @exception.class == TimeoutError
    end
  end
end
