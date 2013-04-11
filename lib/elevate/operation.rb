module Elevate
  class ElevateOperation < NSOperation
    def initWithTarget(target, args:args)
      if init()
        @coordinator = IOCoordinator.new
        @context = TaskContext.new(args, &target)
        @update_callback = nil
        @finish_callback = nil

        setCompletionBlock(lambda do
          if @finish_callback
            @finish_callback.call(@result, @exception) unless isCancelled
          end

          Dispatch::Queue.main.sync do
            @context = nil
            @update_callback = nil
            @finish_callback = nil
          end
        end)
      end

      self
    end

    def cancel
      @coordinator.cancel

      super
    end

    def inspect
      details = []
      details << "<canceled>" if @coordinator.cancelled?

      "#<#{self.class.name}: #{details.join(" ")}>"
    end

    def log(line)
      puts line unless RUBYMOTION_ENV == "test"
    end

    def main
      log " START: #{inspect}"

      @coordinator.install

      begin
        unless @coordinator.cancelled?
          @result = @context.execute do |*args|
            @update_callback.call(*args) if @update_callback
          end
        end

      rescue Exception => e
        @exception = e
      end

      @coordinator.uninstall

      log "FINISH: #{inspect}"
    end

    attr_reader :exception
    attr_reader :result

    def on_finish=(callback)
      @finish_callback = callback
    end

    def on_start=(callback)
      start_callback = callback
      start_callback.retain

      Dispatch::Queue.main.async do
        start_callback.call unless isCancelled
        start_callback.release
      end
    end

    def on_update=(callback)
      @update_callback = callback
    end
  end
end
