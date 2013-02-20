module Elevate
module HTTP
  class RequestError < RuntimeError
    def initialize(error)
      super(error.localizedDescription)

      @code = error.code
    end

    attr_reader :code
  end

  class OfflineError < RequestError
  end
end
end
