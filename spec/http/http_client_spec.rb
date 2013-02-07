describe Elevate::HTTP::HTTPClient do
  extend WebStub::SpecHelpers

  before do
    disable_network_access!

    @base_url = "http://www.example.com"
    @path = "/resource/action"
    @url = @base_url + @path

    @client = Elevate::HTTP::HTTPClient.new(@base_url)
  end

  it "issues requests to the complete URL" do
    stub_request(:get, @url).to_return(status_code: 201)

    @client.get(@path).status_code.should == 201
  end

  it "appends query parameters to the URL" do
    stub_request(:get, @url + "?q=help&page=2").to_return(json: { result: 0 })

    @client.get(@path, q: "help", page: 2).body.should == { "result" => 0 }
  end

  it "decodes JSON responses" do
    result = { "int" => 42, "string" => "hi", "dict" => { "boolean" => true }, "array" => [1,2,3] }
    stub_request(:get, @url).to_return(json: result)

    @client.get(@path).body.should == result
  end

  it "encodes JSON bodies" do
   stub_request(:post, @url).
      with(json: { string: "hello", array: [1,2,3] }).
      to_return(json: { result: true })

    @client.post(@path, { string: "hello", array: [1,2,3] }).body.should == { "result" => true }
  end
end
