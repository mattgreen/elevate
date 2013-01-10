module Masamune
module HTTP
  class HTTPClient
    def initialize(base_url)
      if base_url.end_with? "/"
        base_url = base_url.chop
      end

      @base_url = base_url
    end

    def get(path, query={})
      issue(:GET, path, nil, query: query)
    end

    def post(path, body)
      issue(:post, path, body)
    end

    def put(path, body)
      issue(:put, path, body)
    end

    def delete(path)
      issue(:delete, path, nil)
    end

    private

    def issue(method, path, body, options={})
      url = url_for(path, options[:query])
      puts url

      options[:headers] ||= {}
      options[:headers]["Accept"] = "application/json"

      if body
        options[:body] = NSJSONSerialization.dataWithJSONObject(body, options:0, error:nil)
        options[:headers]["Content-Type"] = "application/json"
      end

      request = HTTPRequest.new(method, url, options)

      IOCoordinator.register_blocking(request) do
        JSONHTTPResponse.new(request.response)
      end
    end

    def url_for(path, query)
      unless path.start_with? "/"
        path = "/" + path
      end
      
      url = @base_url + path
      if ! query.nil? && ! query.empty?
        url += "?" + URI.encode_query(query)
      end

      url
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
