module Elevate
module HTTP
  # TODO: redirects
  class HTTPRequest
    METHODS = [:get, :post, :put, :delete, :patch, :head, :options].freeze
    QUEUE = NSOperationQueue.alloc.init

    def initialize(method, url, options={})
      raise ArgumentError, "invalid HTTP method" unless METHODS.include? method.downcase
      raise ArgumentError, "invalid URL" unless url.start_with? "http"
      raise ArgumentError, "invalid body type; must be NSData" if options[:body] && ! options[:body].is_a?(NSData)

      unless options.fetch(:query, {}).empty?
        url += "?" + URI.encode_query(options[:query])
      end

      @request = NSMutableURLRequest.alloc.init
      @request.CachePolicy = NSURLRequestReloadIgnoringLocalCacheData
      @request.HTTPBody = options[:body]
      @request.HTTPMethod = method
      @request.URL = NSURL.URLWithString(url)

      headers = options.fetch(:headers, {})

      if credentials = options[:credentials]
        headers["Authorization"] = get_authorization_header(credentials)
      end

      headers.each do |key, value|
        @request.setValue(value.to_s, forHTTPHeaderField:key.to_s)
      end

      @response = HTTPResponse.new

      @connection = nil
      @promise = Promise.new
    end

    def cancel
      return unless started?

      @connection.cancel()
      @promise.set(nil)
    end

    def response
      unless started?
        start()
      end

      @promise.get()
    end

    def start
      @connection = NSURLConnection.alloc.initWithRequest(@request, delegate:self, startImmediately:false)
      @connection.setDelegateQueue(QUEUE)
      @connection.start()
    end

    def started?
      @connection != nil
    end

    private

    def connection(connection, didReceiveResponse: response)
      @response.headers = response.allHeaderFields
      @response.status_code = response.statusCode
    end

    def connection(connection, didReceiveData: data)
      @response.append_data(data)
    end

    def connection(connection, didFailWithError: error)
      puts "ERROR: #{error.localizedDescription}"

      @response.error = error
      @response.freeze

      @promise.set(@response)
    end

    def connectionDidFinishLoading(connection)
      @response.freeze

      @promise.set(@response)
    end

    def get_authorization_header(credentials)
      "Basic " + Base64.encode("#{credentials[:username]}:#{credentials[:password]}")
    end    
  end
end
end
