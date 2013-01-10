module Masamune
module HTTP
  class HTTPResponse
    def initialize
      @body = nil
      @headers = nil
      @status_code = nil
      @error = nil
    end

    def append_data(data)
      @body ||= NSMutableData.alloc.init
      @body.appendData(data)
    end

    attr_reader   :body
    attr_accessor :headers
    attr_accessor :status_code
    attr_accessor :error
  end
end
end
