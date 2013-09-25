module Elevate
  class Future
    OUTSTANDING = 0
    FULFILLED = 1

    def initialize
      @lock = NSConditionLock.alloc.initWithCondition(OUTSTANDING)
      @value = nil
    end

    def fulfill(value)
      if @lock.tryLockWhenCondition(OUTSTANDING)
        @value = value
        @lock.unlockWithCondition(FULFILLED)
      end
    end

    def value
      value = nil

      @lock.lockWhenCondition(FULFILLED)
      value = @value
      @lock.unlockWithCondition(FULFILLED)

      value
    end
  end
end
