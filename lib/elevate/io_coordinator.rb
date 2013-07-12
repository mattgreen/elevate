module Elevate
  # Implements task cancellation.
  #
  # Compliant I/O mechanisms (such as HTTP requests) register long-running
  # operations with a well-known instance of this class. When a cancellation
  # request is received from another thread, the long-running operation is
  # cancelled.
  class IOCoordinator
    # Retrieves the current IOCoordinator for this thread.
    #
    # @return [IOCoordinator,nil]
    #   IOCoordinator previously installed to this thread
    #
    # @api public
    def self.for_thread
      Thread.current[:io_coordinator]
    end

    # Initializes a new IOCoordinator with the default state.
    #
    # @api private
    def initialize
      @lock = NSLock.alloc.init
      @blocking_operation = nil
      @cancelled = false
      @exception_class = nil
    end

    # Cancels the I/O operation (if any), raising an exception of type 
    # +exception_class+ in the worker thread.
    #
    # If the thread is not currently blocked, then set a flag requesting cancellation.
    #
    # @return [void]
    #
    # @api private
    def cancel(exception_class = CancelledError)
      blocking_operation = nil

      @lock.lock
      @cancelled = true
      @exception_class = exception_class
      blocking_operation = @blocking_operation
      @lock.unlock

      if blocking_operation
        blocking_operation.cancel
      end
    end

    # Returns the cancelled flag.
    #
    # @return [Boolean]
    #   true if this coordinator has been +cancel+ed previously.
    #
    # @api private
    def cancelled?
      cancelled = nil

      @lock.lock
      cancelled = @cancelled
      @lock.unlock

      cancelled
    end

    # Installs this IOCoordinator to a well-known thread-local.
    #
    # @return [void]
    #
    # @api private
    def install
      Thread.current[:io_coordinator] = self
    end

    # Marks the specified operation as one that will potentially block the
    # worker thread for a significant amount of time.
    #
    # @param operation [#cancel]
    #   operation responsible for blocking
    #
    # @return [void]
    #
    # @api public
    def signal_blocked(operation)
      check_for_cancellation

      @lock.lock
      @blocking_operation = operation
      @lock.unlock
    end

    # Signals that the specified operation has completed, and is no longer
    # responsible for blocking the worker thread.
    #
    # @return [void]
    #
    # @api public
    def signal_unblocked(operation)
      @lock.lock
      @blocking_operation = nil
      @lock.unlock

      check_for_cancellation
    end

    # Removes the thread-local for the calling thread.
    #
    # @return [void]
    #
    # @api private
    def uninstall
      Thread.current[:io_coordinator] = nil
    end

    private

    def check_for_cancellation
      raise @exception_class if cancelled?
    end
  end

  # Raised when a task is cancelled.
  #
  # @api public
  class CancelledError < StandardError
  end

  # Raised when a task's timeout expires
  #
  # @api public
  class TimeoutError < CancelledError
  end
end
