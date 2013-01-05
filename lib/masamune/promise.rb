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
      @lock.unlockWithCondition(OUTSTANDING)

      result
    end

    def set(result)
      @lock.lock()
      @result = result
      @lock.unlockWithCondition(FULFILLED)
    end
  end
end
