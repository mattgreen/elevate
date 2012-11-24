module Interactor
  class InteractorOperation < NSOperation
    def initWithTarget(target)
      if init()
        @target = target
        @dispatcher = Dispatcher.new

        setCompletionBlock(lambda do
          @target = nil

          @dispatcher.invoke_finished_callback() unless isCancelled()
          @dispatcher.dispose()
        end)
      end

      self
    end

    def dealloc
      puts 'dealloc!'

      super
    end

    def main
      @result = @target.execute

    rescue => e
      @exception = e
    end

    attr_reader :exception
    attr_reader :result

    def on_started=(callback)
      @dispatcher.on_started = callback
    end

    def on_finished=(callback)
      @dispatcher.on_finished = callback
    end
  end
end
