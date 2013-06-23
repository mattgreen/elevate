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

      it "sends query strings when the query option is used" do
        stub = stub_request(m, "#{@url}?a=1&b=hello&c=4.2")

        Elevate::HTTP.send(m, @url, query: { a: 1, b: "hello", c: "4.2" })

        stub.should.be.requested
      end

      it "sends headers when the header option is used" do
        stub = stub_request(m, @url).with(headers: { "API-Key" => "secret" })

        Elevate::HTTP.send(m, @url, headers: { "API-Key" => "secret" })

        stub.should.be.requested
      end

      it "sends a body when the body option is used" do
        stub = stub_request(m, @url).with(body: "hello")

        Elevate::HTTP.send(m, @url, body: "hello".dataUsingEncoding(NSUTF8StringEncoding))

        stub.should.be.requested
      end

      it "returns a Response" do
        stub_request(m, @url).to_return(body: "hello", headers: { "X-TestHeader" => "Value" }, status_code: 204)

        response = Elevate::HTTP.send(m, @url)

        NSString.alloc.initWithData(response.body, encoding: NSUTF8StringEncoding).should == "hello"
        response.headers.keys.should.include("X-TestHeader")
        response.status_code.should == 204
        response.url.should == @url
      end

      describe "when the response is encoded as JSON" do
        before do
          stub_request(m, @url).to_return(json: { user_id: "3", token: "secret" })
        end

        it "should automatically decode it" do
          response = Elevate::HTTP.send(m, @url)

          response.body.should == { "user_id" => "3", "token" => "secret" }
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
          lambda { Elevate::HTTP.send(m, @url) }.should.raise(Elevate::HTTP::RequestError)
        end
      end

      #describe "when the Internet connection is offline" do
        #it "raises an OfflineError" do
        # TODO: extend WebStub to return specific error codes
        #end
      #end
    end
  end
end
