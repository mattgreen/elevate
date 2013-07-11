describe Elevate::HTTP do
  extend WebStub::SpecHelpers

  before  { disable_network_access! }
  after   { enable_network_access! }

  before do
    @url = "http://www.example.com/"
  end

  Elevate::HTTP::Request::METHODS.each do |m|
    describe ".#{m}" do
      it "synchronously issues a HTTP #{m} request" do
        stub = stub_request(m, @url)
        Elevate::HTTP.send(m, @url)

        stub.should.be.requested
      end
    end
  end

  describe "Request options" do
    it "encodes query string of :headers" do
      stub = stub_request(:get, "#{@url}?a=1&b=hello&c=4.2")

      Elevate::HTTP.get(@url, query: { a: 1, b: "hello", c: "4.2" })

      stub.should.be.requested
    end

    it "sends headers specified by :headers" do
      stub = stub_request(:get, @url).
        with(headers: { "API-Key" => "secret" })

      Elevate::HTTP.get(@url, headers: { "API-Key" => "secret" })

      stub.should.be.requested
    end

    it "sends body content specified by :body" do
      stub = stub_request(:post, @url).with(body: "hello")

      Elevate::HTTP.post(@url, body: "hello".dataUsingEncoding(NSUTF8StringEncoding))

      stub.should.be.requested
    end

    describe "with a JSON body" do
      it "encodes JSON dictionary specified by :json" do
        stub = stub_request(:post, @url).with(body: '{"test":"secret"}')

        Elevate::HTTP.post(@url, json: { "test" => "secret" })

        stub.should.be.requested
      end

      it "encodes JSON array specified by :json" do
        stub = stub_request(:post, @url).with(body: '["1","2"]')

        Elevate::HTTP.post(@url, json: ["1", "2"])

        stub.should.be.requested
      end

      it "sets the correct Content-Type" do
        stub = stub_request(:post, @url).
          with(body: '{"test":"secret"}', headers: { "Content-Type" => "application/json" })

        Elevate::HTTP.post(@url, json: { "test" => "secret" })

        stub.should.be.requested
      end
    end

    describe "with a form body" do
      it "encodes form data specified by :form" do
        stub = stub_request(:post, @url).with(body: { "test" => "secret", "user" => "matt" })

        Elevate::HTTP.post(@url, form: { "test" => "secret", "user" => "matt" })

        stub.should.be.requested
      end

      it "sets the correct Content-Type" do
        stub = stub_request(:post, @url).
          with(body: { "test" => "secret", "user" => "matt" }, headers: { "Content-Type" => "application/x-www-form-urlencoded" })

        Elevate::HTTP.post(@url, form: { "test" => "secret", "user" => "matt" })

        stub.should.be.requested
      end
    end
  end

  describe "Response" do
    it "returns a Response" do
      stub_request(:get, @url).
        to_return(body: "hello",
                  headers: { "X-TestHeader" => "Value" }, 
                  status_code: 204)

      response = Elevate::HTTP.get(@url)

      NSString.alloc.initWithData(response.body, encoding: NSUTF8StringEncoding).should == "hello"
      NSString.alloc.initWithData(response.raw_body, encoding: NSUTF8StringEncoding).should == "hello"
      response.error.should.be.nil
      response.headers.keys.should.include("X-TestHeader")
      response.status_code.should == 204
      response.url.should == @url
    end

    describe "when the response is encoded as JSON" do
      it "should automatically decode it" do
        stub_request(:get, @url).
          to_return(json: { user_id: "3", token: "secret" })

        response = Elevate::HTTP.get(@url)

        response.body.should == { "user_id" => "3", "token" => "secret" }
      end

      describe "when a JSON dictionary is returned" do
        it "the returned response should behave like a Hash" do
          stub_request(:get, @url).
            to_return(json: { user_id: "3", token: "secret" })

          response = Elevate::HTTP.get(@url)

          response["user_id"].should == "3"
        end
      end

      describe "when a JSON array is returned" do
        it "the returned response should behave like an Array" do
          stub_request(:get, @url).
            to_return(json: ["apple", "orange", "pear"])

          response = Elevate::HTTP.get(@url)

          response.length.should == 3
        end
      end
    end

    describe "when the response is redirected" do
      it "redirects to the final URL" do
        @redirect_url = @url + "redirected"

        stub_request(:get, @redirect_url).to_return(body: "redirected")
        stub_request(:get, @url).to_redirect(url: @redirect_url)

        response = Elevate::HTTP.get(@url)
        response.url.should == @redirect_url
      end

      describe "with an infinite redirect loop" do
        before do
          @url2 = @url + "redirect"

          stub_request(:get, @url).to_redirect(url: @url2)
          stub_request(:get, @url2).to_redirect(url: @url)
        end

        it "raises a RequestError" do
          lambda { Elevate::HTTP.get(@url) }.
            should.raise(Elevate::HTTP::RequestError)
        end
      end
    end

    #describe "when the response has a HTTP error status" do
      #it "raises RequestError" do
        #stub_request(m, @url).to_return(status_code: 422)

        #lambda { Elevate::HTTP.send(m, @url) }.should.raise(Elevate::HTTP::RequestError)
      #end
    #end

    describe "when the request cannot be fulfilled" do
      it "raises a RequestError" do
        lambda { Elevate::HTTP.get(@url) }.
          should.raise(Elevate::HTTP::RequestError)
      end
    end

    describe "when the Internet connection is offline" do
      it "raises an OfflineError" do
        stub_request(:get, @url).to_fail(code: NSURLErrorNotConnectedToInternet)

        lambda { Elevate::HTTP.get(@url) }.
          should.raise(Elevate::HTTP::OfflineError)
      end
    end
  end
end
