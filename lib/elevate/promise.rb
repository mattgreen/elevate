module Elevate
  class Promise
    OUTSTANDING = 0
    FULFILLED = 1

    def initialize
      @lock = NSConditionLock.alloc.initWithCondition(OUTSTANDING)
      @result = nil
    end

    def fulfill(result)
      if @lock.tryLockWhenCondition(OUTSTANDING)
        @result = result
        @lock.unlockWithCondition(FULFILLED)
      end
    end

    def value
      result = nil

      @lock.lockWhenCondition(FULFILLED)
      result = @result
      @lock.unlockWithCondition(FULFILLED)

      result
    end
  end
end
