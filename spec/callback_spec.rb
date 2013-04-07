describe Elevate::Callback do
  describe "#call" do
    describe "on the main thread" do
      it "invokes the block within the provided context" do
        callback = Elevate::Callback.new(self, lambda { |v| @value = v })
        callback.call(42)

        @value.should == 42
      end
    end

    describe "on a background thread" do
      it "invokes the block within the provided context on the main thread" do
        callback = Elevate::Callback.new(self, lambda { @thread = NSThread.currentThread })
        callback.call

        @thread.should == NSThread.mainThread
      end
    end
  end
end

