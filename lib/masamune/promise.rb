module Masamune
  class Promise
    OUTSTANDING = 0
    FULFILLED = 1

    def initialize
      @lock = NSConditionLock.alloc.initWithCondition(OUTSTANDING)
      @result = nil
    end

    def get
      result = nil

      @lock.lockWhenCondition(FULFILLED)
      result = @result
      @lock.unlockWithCondition(FULFILLED)

      result
    end

    def set(result)
      @lock.lockWhenCondition(OUTSTANDING)
      @result = result
      @lock.unlockWithCondition(FULFILLED)
    end
  end
end
