class ThreadsafeProxy
  def initialize(target)
    @mutex = Mutex.new
    @target = target
  end

  def method_missing(m, *args, &block)
    @mutex.synchronize do
      @target.__send__(m, *args, &block)
    end
  end

  def respond_to_missing?(m, include_private = false)
    @mutex.synchronize do
      @target.respond_to_missing?(m, include_private)
    end
  end
end
