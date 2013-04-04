module Elevate
  class ElevateOperation < NSOperation
    def initWithTarget(target, context: context)
      if init()
        @coordinator = IOCoordinator.new
        @target = target
        @context = context
        @finished_callback  = lambda { |*args| }

        setCompletionBlock(lambda do
          @finished_callback.call unless isCancelled

          Dispatch::Queue.main.sync do
            @target = nil
            @context = nil
            @finished_callback = nil
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
      details << "@target=#{@target.class.name}"

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
          if @target.is_a?(Proc)
            @result = @context.instance_eval(&@target)
          else
            @result = @target.call
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

    def on_started=(callback)
      started_callback = Callback.new(@context, self, callback)
      started_callback.retain

      Dispatch::Queue.main.async do
        started_callback.call unless isCancelled
        started_callback.release
      end
    end

    def on_finished=(callback)
      @finished_callback = Callback.new(@context, self, callback)
    end
  end
end
