describe Elevate::HTTP::HTTPRequest do
  extend WebStub::SpecHelpers

  before do
    disable_network_access!
  end

  before do
    @url = "http://www.example.com/"
    @body = "hello"
  end

  it "requires a valid HTTP method" do
    lambda { Elevate::HTTP::HTTPRequest.new(:invalid, @url) }.should.raise(ArgumentError)
  end

  it "requires a URL starting with http" do
    lambda { Elevate::HTTP::HTTPRequest.new(:get, "asdf") }.should.raise(ArgumentError)
  end

  it "requires the body to be an instance of NSData" do
    lambda { Elevate::HTTP::HTTPRequest.new(:get, @url, body: @body) }.should.raise(ArgumentError)
  end

  describe "fulfilling a GET request" do
    before do
      stub_request(:get, @url).
        to_return(body: @body, headers: {"Content-Type" => "text/plain"}, status_code: 201)

      @request = Elevate::HTTP::HTTPRequest.new(:get, @url)
      @response = @request.response
    end

    it "response has the correct status code" do
      @response.status_code.should == 201
    end

    it "response has the right body" do
      NSString.alloc.initWithData(@response.body, encoding:NSUTF8StringEncoding).should == @body
    end

    it "response has the correct headers" do
      @response.headers.should == { "Content-Type" => "text/plain" }
    end

    it "response has no errors" do
      @response.error.should.be.nil
    end
  end

  describe "fulfilling a GET request with headers" do
    before do
      stub_request(:get, @url).with(headers: { "API-Token" => "abc123" }).to_return(body: @body)

      @request = Elevate::HTTP::HTTPRequest.new(:get, @url, headers: { "API-Token" => "abc123" })
      @response = @request.response
    end

    it "includes the headers in the request" do
      @response.body.should.not.be.nil
    end
  end

  describe "fulfilling a POST request with a body" do
    before do
      stub_request(:post, @url).with(body: @body).to_return(body: @body)
    end

    it "sends the body as part of the request" do
      request = Elevate::HTTP::HTTPRequest.new(:post, @url, body: @body.dataUsingEncoding(NSUTF8StringEncoding))
      response = request.response

      NSString.alloc.initWithData(response.body, encoding:NSUTF8StringEncoding).should == @body
    end
  end

  describe "cancelling a request" do
    before do
      stub_request(:get, @url).to_return(body: @body, delay: 1.0)
    end

    it "aborts the request" do
      start = Time.now

      request = Elevate::HTTP::HTTPRequest.new(:get, @url)
      request.start()
      request.cancel()

      response = request.response # simulate blocking
      finish = Time.now

      (finish - start).should < 1.0
    end

    it "sets the response to nil" do
      request = Elevate::HTTP::HTTPRequest.new(:get, @url)
      request.start()
      request.cancel()

      request.response.should.be.nil
    end
  end
end
