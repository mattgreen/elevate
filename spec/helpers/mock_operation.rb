class MockOperation
  def initialize
    @isCancelled = false
    @isFinished = false
  end

  attr_accessor :isCancelled
  attr_accessor :isFinished
end
