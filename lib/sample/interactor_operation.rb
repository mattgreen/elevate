class InteractorOperation < NSOperation
  def initWithTarget(target)
    if init()
      @target = target
    end

    self
  end

  def main
    @result = @target.execute

  rescue => e
    @exception = e
  ensure
    @target = nil
  end

  attr_reader :exception
  attr_reader :result
end
