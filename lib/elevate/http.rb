module Elevate
module HTTP
  Request::METHODS.each do |m|
    define_singleton_method(m) do |url, options = {}|
      coordinator = IOCoordinator.for_thread

      request = Request.new(m, url, options)

      coordinator.signal_blocked(request) if coordinator
      response = request.response
      coordinator.signal_unblocked(request) if coordinator

      if error = response.error
        if error.code == NSURLErrorNotConnectedToInternet
          raise OfflineError, error
        else
          raise RequestError, response.error
        end
      end

      response
    end
  end
end
end
