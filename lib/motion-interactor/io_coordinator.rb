class IOCoordinator
  def self.for_thread
    Thread.current[:io_coordinator]
  end

  def initialize
    @mutex = Mutex.new
    @blocking_operation = nil
    @cancelled = false
  end

  def cancel
    blocking_operation = nil

    @mutex.synchronize do
      @cancelled = true
      blocking_operation = @blocking_operation
    end

    if blocking_operation
      blocking_operation.cancel()
    end
  end

  def cancelled?
    @mutex.synchronize do
      @cancelled
    end
  end

  def install
    Thread.current[:io_coordinator] = self
  end

  def signal_blocking(operation)
    check_for_cancellation

    @mutex.synchronize do
      @blocking_operation = operation
    end
  end

  def signal_unblocked(operation)
    @mutex.synchronize do
      @blocking_operation = nil
    end

    check_for_cancellation
  end

  def uninstall
    Thread.current[:io_coordinator] = nil
  end

private

  def check_for_cancellation
    cancelled = false
    @mutex.synchronize do
      cancelled = @cancelled
    end

    raise CancelledError if cancelled
  end
end

class CancelledError < StandardError
end
