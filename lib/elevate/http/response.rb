module Elevate
module HTTP
  class Response
    def initialize
      @body = nil
      @headers = nil
      @status_code = nil
      @error = nil
      @raw_body = nil
      @url = nil
    end

    def append_data(data)
      @raw_body ||= NSMutableData.alloc.init
      @raw_body.appendData(data)
    end

    def body
      @body ||= begin
        if json?
          NSJSONSerialization.JSONObjectWithData(@raw_body, options: 0, error: nil)
        else
          @raw_body
        end
      end
    end

    def freeze
      body

      super
    end

    def method_missing(m, *args, &block)
      return super unless json?

      body.send(m, *args, &block)
    end

    def respond_to_missing?(m, include_private = false)
      return false unless json?

      body.respond_to_missing?(m, include_private)
    end

    attr_accessor :headers
    attr_accessor :status_code
    attr_accessor :error
    attr_reader   :raw_body
    attr_accessor :url

    private

    def json?
      headers && headers["Content-Type"] =~ %r{application/json}
    end
  end
end
end
