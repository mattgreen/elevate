module Elevate
module HTTP
  # Encapsulates a response received from a HTTP server.
  #
  # @api public
  class Response
    def initialize
      @body = nil
      @headers = nil
      @status_code = nil
      @error = nil
      @raw_body = nil
      @url = nil
    end

    # Appends a chunk of data to the body.
    #
    # @api private
    def append_data(data)
      @raw_body ||= NSMutableData.alloc.init
      @raw_body.appendData(data)
    end

    # Returns the body of the response.
    #
    # If the body is JSON-encoded, it will be decoded and returned.
    #
    # @return [NSData, Hash, Array, nil]
    #   response body, if any. If the response is JSON-encoded, the decoded body.
    #
    # @api public
    def body
      @body ||= begin
        if json?
          NSJSONSerialization.JSONObjectWithData(@raw_body, options: 0, error: nil)
        else
          @raw_body
        end
      end
    end

    # Freezes this instance, making it immutable.
    #
    # @api private
    def freeze
      body

      super
    end

    # Forwards unknown methods to +body+, enabling this object to behave like +body+.
    #
    # This only occurs if +body+ is a Ruby collection.
    #
    # @api public
    def method_missing(m, *args, &block)
      return super unless json?

      body.send(m, *args, &block)
    end

    # Handles missing method queries, allowing +body+ masquerading.
    #
    # @api public
    def respond_to_missing?(m, include_private = false)
      return false unless json?

      body.respond_to_missing?(m, include_private)
    end

    # Returns the HTTP headers
    #
    # @return [Hash]
    #   returned headers
    #
    # @api public
    attr_accessor :headers

    # Returns the HTTP status code
    #
    # @return [Integer]
    #   status code of the response
    #
    # @api public
    attr_accessor :status_code

    attr_accessor :error

    # Returns the raw body
    #
    # @return [NSData]
    #   response body
    #
    # @api public
    attr_reader   :raw_body

    # Returns the URL
    #
    # @return [String]
    #   URL of the response
    #
    # @api public
    attr_accessor :url

    private

    def json?
      headers && headers["Content-Type"] =~ %r{application/json}
    end
  end
end
end
