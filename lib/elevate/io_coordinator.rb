module Elevate
  class IOCoordinator
    def self.for_thread
      Thread.current[:io_coordinator]
    end

    def initialize
      @lock = NSLock.alloc.init
      @blocking_operation = nil
      @cancelled = false
    end

    def cancel
      blocking_operation = nil

      @lock.lock()
      @cancelled = true
      blocking_operation = @blocking_operation
      @lock.unlock()

      if blocking_operation
        blocking_operation.cancel()
      end
    end

    def cancelled?
      cancelled = nil

      @lock.lock()
      cancelled = @cancelled
      @lock.unlock()

      cancelled
    end

    def install
      Thread.current[:io_coordinator] = self
    end

    def signal_blocked(operation)
      check_for_cancellation

      @lock.lock()
      @blocking_operation = operation
      @lock.unlock()
    end

    def signal_unblocked(operation)
      @lock.lock()
      @blocking_operation = nil
      @lock.unlock()

      check_for_cancellation
    end

    def uninstall
      Thread.current[:io_coordinator] = nil
    end

    private

    def check_for_cancellation
      raise CancelledError if cancelled?
    end
  end

  class CancelledError < StandardError
  end
end
