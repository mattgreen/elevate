module Elevate
  # A blank slate for hosting task blocks.
  #
  # Because task blocks run in another thread, it is dangerous to expose them
  # to the calling context. This class acts as a sandbox for task blocks.
  #
  # @api private
  class TaskContext
    def initialize(block, channel, args)
      @__block = block
      @__channel = channel
      @__args = args
    end

    def execute
      instance_exec(&@__block)
    end

    def task_args
      @__args
    end

    def update(*args)
      @__channel << args if @__channel
    end
  end
end
