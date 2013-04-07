module Elevate
  class Context
    def initialize(args, &block)
      metaclass = class << self; self; end
      metaclass.send(:define_method, :execute, &block)

      args.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end

  class ElevateOperation < NSOperation
    def initWithTarget(target, args:args)
      if init()
        @coordinator = IOCoordinator.new
        @target = target
        @context = Context.new(args, &target)
        @finished_callback = nil

        setCompletionBlock(lambda do
          if @finished_callback
            @finished_callback.call(@result, @exception) unless isCancelled
          end

          Dispatch::Queue.main.sync do
            @target = nil
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
          @result = @context.execute
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
      started_callback = callback
      started_callback.retain

      Dispatch::Queue.main.async do
        started_callback.call unless isCancelled
        started_callback.release
      end
    end

    def on_finished=(callback)
      @finished_callback = callback
    end
  end
end
