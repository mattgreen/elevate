module Masamune
  module IO
    class HTTPClient
      def initialize(base_url)
        @base_url = base_url
      end

      def get(path, query={})
        issue(:GET, path, query: query)
      end

    private

      def issue(method, path, options={})
        request = HTTPRequest.new(method, url, options)

        IOCoordinator.register_blocking(request) do
          request.fulfill()
        end
      end

    end

    class HTTPRequest
      def initialize(method, url, options={})
        @request = NSMutableURLRequest.alloc.init
        @request.CachePolicy = NSURLRequestReloadIgnoringLocalCacheData
        @request.HTTPBody = options[:body]
        @request.HTTPMethod = method
        @request.URL = NSURL.URLWithString(url)

        @connection = nil
        @queue = nil

        @response = Promise.new
        @response_body = NSMutableData.alloc.init
        @response_headers = nil
        @response_status_code = nil
      end

      def cancel
        return if @connection.nil?

        @connection.cancel()
      end

      def response
        if @connection.nil?
          @connection = NSURLConnection.alloc.initWithRequest(@request, delegate:self, startImmediately:false)
          @queue = NSOperationQueue.alloc.init
          @connection.setDelegateQueue(@queue)
          @connection.start()
        end

        @queue.waitUntilAllOperationsAreFinished()

        @response.get()
      end

    private

      def connection(connection, didReceiveResponse: response)
        @response_body.length = 0
        @response_headers = response.allHeaderFields
        @response_status_code = response.statusCode
      end

      def connection(connection, didReceiveData: data)
        @response_body.appendData(data)
      end

      def connection(connection, didFailWithError: error)
        @response.set(HTTPResponse.new(nil, nil, nil, error))
      end

      def connectionDidFinishLoading(connection)
        @response.set(HTTPResponse.new(@response_body, @response_headers, @response_status_code, nil))
      end
    end

    class HTTPResponse
      def initialize(body, headers, status_code, error)
        @body = body
        @headers = headers
        @status_code = status_code
        @error = error
      end

      attr_reader :body
      attr_reader :headers
      attr_reader :status_code
      attr_reader :error
    end
  end
end
