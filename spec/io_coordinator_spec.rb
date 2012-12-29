describe IOCoordinator do
  before do
    @coordinator = IOCoordinator.new
  end

  it "is not cancelled" do
    @coordinator.should.not.be.cancelled
  end

  describe "#install" do
    it "stores the coordinator in a thread-local variable" do
      @coordinator.install()

      Thread.current[:io_coordinator].should == @coordinator
    end
  end

  describe "#signal_blocked" do
    describe "when IO has not been cancelled" do
      it "does not raise CancelledError" do
        lambda { @coordinator.signal_blocked(42) }.should.not.raise
      end
    end

    describe "when IO was cancelled" do
      it "raises CancelledError" do
        @coordinator.cancel()

        lambda { @coordinator.signal_blocked(42) }.should.raise(CancelledError)
      end
    end
  end

  describe "#uninstall" do
    it "removes the coordinator from a thread-local variable" do
      @coordinator.install()
      @coordinator.uninstall()

      Thread.current[:io_coordinator].should.be.nil
    end
  end
end
