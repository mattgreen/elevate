module Masamune
  class MasamuneOperation < NSOperation
    def initWithTarget(target)
      if init()
        @target = target
        @coordinator = IOCoordinator.new
        @dispatcher = Dispatcher.new

        setCompletionBlock(lambda do
          @target = nil

          @dispatcher.invoke_finished_callback() unless isCancelled()
          @dispatcher.dispose()
        end)
      end

      self
    end

    def cancel
      @coordinator.cancel()

      super
    end

    def dealloc
      #puts 'dealloc!'

      super
    end

    def inspect
      details = []
      details << "<canceled>" if @coordinator.cancelled?
      details << "@target=#{@target.class.name}"

      "#<#{self.class.name}: #{details.join(" ")}>"
    end

    def log(line)
      puts line unless RUBYMOTION_ENV == "test"
    end

    def main
      log " START: #{inspect}"

      @coordinator.install()

      begin
        unless @coordinator.cancelled?
          @result = @target.execute
        end

      rescue => e
        @exception = e
      end

      @coordinator.uninstall()

      log "FINISH: #{inspect}"
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
