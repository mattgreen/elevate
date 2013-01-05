describe Masamune::IO::HTTPRequest do
  extend WebStub::SpecHelpers

  before do
    disable_network_access!
  end

  describe "#response" do
    [:GET, :POST, :PUT, :DELETE, :PATCH, :HEAD].each do |method|
      describe "with a valid request" do
        before do
          stub_request(method.downcase, 'http://www.example.com/').
            to_return(body: "hello")

          @request = Masamune::IO::HTTPRequest.new(method.upcase, 'http://www.example.com/')
          @response = @request.response
        end

        it "has a status code" do
          @response.status_code.should == 200
        end

        it "has a body with the correct length" do
          @response.body.length.should == 5
        end

        it "has a Hash containing headers" do
          @response.headers.should.be.kind_of Hash
        end

        it "has no errors" do
          @response.error.should.be.nil
        end
      end
    end

    describe "with an invalid request" do
    end

    describe "when cancelled" do
      before do
        stub_request(:get, 'http://www.google.com/').
          to_return(body: "hello", delay: 1.5)
      end

      it "aborts the request" do
        @request = Masamune::IO::HTTPRequest.new(:GET, 'http://www.google.com/')
        
        start = Time.now
        @request.cancel()
        finish = Time.now

        (finish - start).should < 0.5
      end
    end
  end
end
