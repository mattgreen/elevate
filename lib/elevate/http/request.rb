module Elevate
module HTTP
  # Encapsulates a HTTP request.
  #
  # +NSURLConnection+ is responsible for fulfilling the request. The response
  # is buffered in memory as it is received, and made available through the
  # +response+ method.
  #
  # @api public
  class Request
    METHODS = [:get, :post, :put, :delete, :patch, :head, :options].freeze

    # Initializes a HTTP request with the specified parameters.
    #
    # @param [String] method
    #   HTTP method to use
    # @param [String] url
    #   URL to load
    # @param [Hash] options
    #   Options to use
    #
    # @option options [Hash] :query
    #   Hash to construct the query string from.
    # @option options [Hash] :headers
    #   Headers to append to the request.
    # @option options [Hash] :credentials
    #   Credentials to be used with HTTP Basic Authentication. Must have a
    #   +:username+ and/or +:password+ key.
    # @option options [NSData] :body
    #   Raw bytes to use as the body.
    # @option options [Hash,Array] :json
    #   Hash/Array to be JSON-encoded as the request body. Sets the
    #   +Content-Type+ header to +application/json+.
    # @option options [Hash] :form
    #   Hash to be form encoded as the request body. Sets the +Content-Type+
    #   header to +application/x-www-form-urlencoded+.
    #
    # @raise [ArgumentError]
    #   if an illegal HTTP method is used
    # @raise [ArgumentError]
    #   if the URL does not start with 'http'
    # @raise [ArgumentError]
    #   if the +:body+ option is not an instance of +NSData+
    def initialize(method, url, options={})
      raise ArgumentError, "invalid HTTP method" unless METHODS.include? method.downcase
      raise ArgumentError, "invalid URL" unless url.start_with? "http"
      raise ArgumentError, "invalid body type; must be NSData" if options[:body] && ! options[:body].is_a?(NSData)

      unless options.fetch(:query, {}).empty?
        url += "?" + URI.encode_query(options[:query])
      end

      options[:headers] ||= {}

      if root = options.delete(:json)
        options[:body] = NSJSONSerialization.dataWithJSONObject(root, options: 0, error: nil)
        options[:headers]["Content-Type"] = "application/json"
      elsif root = options.delete(:form)
        options[:body] = URI.encode_www_form(root).dataUsingEncoding(NSASCIIStringEncoding)
        options[:headers]["Content-Type"] ||= "application/x-www-form-urlencoded"
      end

      @request = NSMutableURLRequest.alloc.init
      @request.CachePolicy = NSURLRequestReloadIgnoringLocalCacheData
      @request.HTTPBody = options[:body]
      @request.HTTPMethod = method
      @request.URL = NSURL.URLWithString(url)
      @request.setTimeoutInterval(options[:timeout_interval].to_i) if options[:timeout_interval]

      headers = options.fetch(:headers, {})

      if credentials = options[:credentials]
        headers["Authorization"] = get_authorization_header(credentials)
      end

      headers.each do |key, value|
        @request.setValue(value.to_s, forHTTPHeaderField:key.to_s)
      end

      #@cache = self.class.cache
      @response = Response.new
      @response.url = url

      @connection = nil
      @future = Future.new
    end

    # Cancels an in-flight request.
    #
    # This method is safe to call from any thread.
    #
    # @return [void]
    #
    # @api public
    def cancel
      return unless sent?

      NetworkThread.cancel(@connection) if @connection
      ActivityIndicator.instance.hide

      @future.fulfill(nil)
    end

    # Returns a response to this request, sending it if necessary
    #
    # This method blocks the calling thread, unless interrupted.
    #
    # @return [Elevate::HTTP::Response, nil]
    #   response to this request, or nil, if this request was canceled
    #
    # @api public
    def response
      unless sent?
        send
      end

      @future.value
    end

    # Sends this request. The caller is not blocked.
    #
    # @return [void]
    #
    # @api public
    def send
      @connection = NSURLConnection.alloc.initWithRequest(@request, delegate:self, startImmediately:false)
      @request = nil

      NetworkThread.start(@connection)
      ActivityIndicator.instance.show
    end

    # Returns true if this request is in-flight
    #
    # @return [Boolean]
    #   true if this request is in-flight
    #
    # @api public
    def sent?
      @connection != nil
    end

    private

    def self.cache
      Dispatch.once do
        @cache = NSURLCache.alloc.initWithMemoryCapacity(0, diskCapacity: 0, diskPath: nil)
        NSURLCache.setSharedURLCache(cache)
      end

      @cache
    end

    def connection(connection, didReceiveResponse: response)
      @response.headers = response.allHeaderFields
      @response.status_code = response.statusCode
    end

    def connection(connection, didReceiveData: data)
      @response.append_data(data)
    end

    def connection(connection, didFailWithError: error)
      @connection = nil

      puts "ERROR: #{error.localizedDescription} (code: #{error.code})" unless RUBYMOTION_ENV == "test"

      @response.error = error

      ActivityIndicator.instance.hide

      response = @response
      @response = nil

      @future.fulfill(response)
    end

    def connectionDidFinishLoading(connection)
      @connection = nil

      ActivityIndicator.instance.hide

      response = @response
      @response = nil

      @future.fulfill(response)
    end

    def connection(connection, willSendRequest: request, redirectResponse: response)
      @response.url = request.URL.absoluteString

      request
    end

    def get_authorization_header(credentials)
      "Basic " + Base64.encode("#{credentials[:username]}:#{credentials[:password]}")
    end
  end
end
end
