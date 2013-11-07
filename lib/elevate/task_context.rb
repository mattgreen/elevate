module Elevate
  # A blank slate for hosting task blocks.
  #
  # Because task blocks run in another thread, it is dangerous to expose them
  # to the calling context. This class acts as a sandbox for task blocks.
  #
  # @api private
  class TaskContext
    def initialize(block, args)
      @__args = args

      metaclass = class << self; self; end
      metaclass.send(:define_method, :execute, &block)
    end

    def task_args
      @__args
    end
  end
end
