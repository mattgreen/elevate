module Elevate
module HTTP
  class HTTPClient
    def initialize(base_url)
      @base_url = NSURL.URLWithString(base_url)
      @credentials = nil
    end

    def get(path, query={}, &block)
      issue(:GET, path, nil, query: query, &block)
    end

    def post(path, body, &block)
      issue(:post, path, body, &block)
    end

    def put(path, body, &block)
      issue(:put, path, body, &block)
    end

    def delete(path, &block)
      issue(:delete, path, nil, &block)
    end

    def set_credentials(username, password)
      @credentials = { username: username, password: password }
    end

    private

    def issue(method, path, body, options={}, &block)
      url = url_for(path)

      options[:headers] ||= {}
      options[:headers]["Accept"] = "application/json"

      if @credentials
        options[:credentials] = @credentials
      end

      if body
        options[:body] = NSJSONSerialization.dataWithJSONObject(body, options:0, error:nil)
        options[:headers]["Content-Type"] = "application/json"
      end

      response = send_request(method, url, options)
      raise_error(response.error) if response.error

      response = JSONHTTPResponse.new(response)
      if response.error == nil && block_given?
        result = yield response.body

        result
      else
        response
      end
    end

    def raise_error(error)
      if error.code == -1009
        raise OfflineError, error
      else
        raise RequestError, response.error
      end
    end

    def send_request(method, url, options)
      request = HTTPRequest.new(method, url, options)

      coordinator = IOCoordinator.for_thread

      coordinator.signal_blocked(request) if coordinator
      response = request.response
      coordinator.signal_unblocked(request) if coordinator

      response
    end

    def url_for(path)
      path = CFURLCreateStringByAddingPercentEscapes(nil, path.to_s, "[]", ";=&,", KCFStringEncodingUTF8)

      NSURL.URLWithString(path, relativeToURL:@base_url).absoluteString
    end
  end

  class JSONHTTPResponse
    def initialize(response)
      @response = response
      @body = decode(response.body)
    end

    def decode(data)
      return nil if data.nil?

      NSJSONSerialization.JSONObjectWithData(data, options:0, error:nil)
    end

    attr_reader :body

    # TODO: delegate
    def error
      @response.error
    end

    def headers
      @response.headers
    end

    def status_code
      @response.status_code
    end
    
  end
end
end
