module Arbiter
  class Dispatcher
    def initialize
      @on_finished = nil
      @on_started = nil
    end

    def dispose
      return if @on_started.nil? && @on_finished.nil?

      # Callbacks must be released on the main thread, because they may contain a strong
      # reference to a UIKit component. See "The Deallocation Problem" for more info.
      unless NSThread.isMainThread
        self.performSelectorOnMainThread(:dispose, withObject: nil, waitUntilDone: true)
        return
      end

      @on_started = nil
      @on_finished = nil
    end

    def invoke_finished_callback
      invoke(:@on_finished)
    end

    def on_finished=(callback)
      @on_finished = callback
    end

    def on_started=(callback)
      @on_started = callback

      Dispatch::Queue.main.async do
        invoke(:@on_started)
      end
    end

    private

    def invoke(callback_name)
      unless NSThread.isMainThread
        self.performSelectorOnMainThread(:"invoke:", withObject: callback_name, waitUntilDone: true)
        return
      end

      if callback = instance_variable_get(callback_name)
        callback.call()

        instance_variable_set(callback_name, nil)
      end
    end
  end
end
