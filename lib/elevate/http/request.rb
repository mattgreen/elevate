module Elevate
module HTTP
  class Request
    METHODS = [:get, :post, :put, :delete, :patch, :head, :options].freeze

    def initialize(method, url, options={})
      raise ArgumentError, "invalid HTTP method" unless METHODS.include? method.downcase
      raise ArgumentError, "invalid URL" unless url.start_with? "http"
      raise ArgumentError, "invalid body type; must be NSData" if options[:body] && ! options[:body].is_a?(NSData)

      if root = options.delete(:json)
        options[:body] = NSJSONSerialization.dataWithJSONObject(root, options: 0, error: nil)

        options[:headers] ||= {}
        options[:headers]["Content-Type"] = "application/json"
      end

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

      @response = Response.new
      @response.url = url

      @connection = nil
      @promise = Promise.new
    end

    def cancel
      return unless started?

      NetworkThread.cancel(@connection)
      ActivityIndicator.instance.hide

      @promise.fulfill(nil)
    end

    def response
      unless started?
        start
      end

      @promise.value
    end

    def start
      @connection = NSURLConnection.alloc.initWithRequest(@request, delegate:self, startImmediately:false)

      NetworkThread.start(@connection)
      ActivityIndicator.instance.show
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
      puts "ERROR: #{error.localizedDescription} (code: #{error.code})" unless RUBYMOTION_ENV == "test"

      @response.error = error
      @response.freeze

      ActivityIndicator.instance.hide

      @promise.fulfill(@response)
    end

    def connectionDidFinishLoading(connection)
      @response.freeze

      ActivityIndicator.instance.hide

      @promise.fulfill(@response)
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
