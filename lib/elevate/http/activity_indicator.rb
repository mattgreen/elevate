module Elevate
module HTTP
  class ActivityIndicator
    def self.instance
      Dispatch.once { @instance = new }

      @instance
    end

    def initialize
      @lock = NSLock.alloc.init
      @count = 0
    end

    def hide
      toggled = false

      @lock.lock
      @count -= 1 if @count > 0
      toggled = @count == 0
      @lock.unlock

      update_indicator(false) if toggled
    end

    def show
      toggled = false

      @lock.lock
      toggled = @count == 0
      @count += 1
      @lock.unlock

      update_indicator(true) if toggled
    end

    private

    def update_indicator(visible)
      UIApplication.sharedApplication.networkActivityIndicatorVisible = visible
    end
  end
end
end
