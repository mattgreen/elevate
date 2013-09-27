module Elevate
  # A simple unidirectional stream of data with a single consumer.
  #
  # @api private
  class Channel
    def initialize(block)
      @target = block
    end

    # Pushes data to consumers immediately
    #
    # @return [void]
    #
    # @api private
    def <<(obj)
      @target.call(obj)
    end
  end
end
