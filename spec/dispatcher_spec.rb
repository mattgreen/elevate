describe Masamune::Dispatcher do
  DELAY = 0.2

  before do
    @dispatcher = Masamune::Dispatcher.new
  end

  describe "#on_started=" do
    before do
      @dispatcher.on_started = lambda { @thread = NSThread.currentThread }
    end

    after do
      @thread = nil
    end

    it "invokes the callback on the main thread" do
      wait DELAY do
        @thread.should == NSThread.currentThread
      end
    end

    it "does not invoke the callback immediately" do
      @thread.should.be.nil
    end
  end

  describe "#on_finished=" do
    before do
      @dispatcher.on_finished = lambda { @thread = NSThread.currentThread }
      @dispatcher.invoke_finished_callback()
    end

    it "invokes the callback on the main thread" do
      wait DELAY do
        @thread.should == NSThread.currentThread
      end
    end
  end
end
