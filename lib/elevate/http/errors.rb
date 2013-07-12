module Elevate
module HTTP
  # Raised when a request could not be completed.
  class RequestError < RuntimeError
    def initialize(error)
      super(error.localizedDescription)

      @code = error.code
    end

    attr_reader :code
  end

  # Raised when the internet connection is offline.
  class OfflineError < RequestError
  end
end
end
