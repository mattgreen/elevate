module Interactor
  class Callback
    def initialize(context, operation, block)
      @context = context
      @operation = operation
      @block = block
    end

    def call
      @context.instance_exec(@operation, &@block)
    end
  end
end
