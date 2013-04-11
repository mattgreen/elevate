module Elevate
  class TaskContext
    def initialize(args, &block)
      metaclass = class << self; self; end
      metaclass.send(:define_method, :execute, &block)

      args.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end
