describe Elevate::ElevateOperation do
  before do
    @target = lambda { @result }
    @operation = Elevate::ElevateOperation.alloc.initWithTarget(@target, args: {}, channel: nil)
    @queue = NSOperationQueue.alloc.init
  end

  after do
    @queue.waitUntilAllOperationsAreFinished
  end

  #describe "#on_finish=" do
    #it "invokes it after #on_started" do
      #@lock = NSLock.alloc.init
      #@value = []

      #@operation.on_start = lambda do
        #@lock.lock()
        #if @value == []
          #@value << 1
        #end
        #@lock.unlock()
      #end

      #@operation.on_finish = lambda do |result, exception|
        #@lock.lock()
        #if @value == [1]
          #@value << 2
        #end
        #@lock.unlock()

        #resume
      #end

      #@queue.addOperation(@operation)

      #wait_max 1.0 do
        #@lock.lock()
        #@value.should == [1,2]
        #@lock.unlock()
      #end
    #end
  #end

  describe "#exception" do
    describe "when no exception is raised" do
      it "returns nil" do
        @queue.addOperation(@operation)
        @operation.waitUntilFinished()

        @operation.exception.should.be.nil
      end
    end

    describe "when an exception is raised" do
      it "returns the exception" do
        @target = lambda { raise IndexError }
        @operation = Elevate::ElevateOperation.alloc.initWithTarget(@target, args: {}, channel: nil)

        @queue.addOperation(@operation)
        @operation.waitUntilFinished()

        @operation.exception.should.not.be.nil
      end
    end
  end

  describe "#result" do
    before do
      @target = lambda { 42 }
      @operation = Elevate::ElevateOperation.alloc.initWithTarget(@target, args: {}, channel: nil)
    end

    describe "before starting the operation" do
      it "returns nil" do
        @operation.result.should.be.nil
      end
    end

    describe "when the operation has been cancelled" do
      it "returns nil" do
        @operation.cancel()

        @queue.addOperation(@operation)
        @operation.waitUntilFinished()

        @operation.result.should.be.nil
      end
    end

    describe "when the operation has finished" do
      it "returns the result of the lambda" do
        @queue.addOperation(@operation)
        @operation.waitUntilFinished()

        @operation.result.should == 42
      end
    end
  end
end
