describe InteractorEventHandler do
  DELAY = 0.1

  before do
    @operation = NSBlockOperation.blockOperationWithBlock(lambda { 42 })
    @queue = NSOperationQueue.alloc.init

    @handler = InteractorEventHandler.new(self, @operation)
  end

  describe "#on_completed" do
    describe "when the operation has completed" do
      before do
        @handler.on_completed do |operation|
          @invoked_context = self
          @finished = @operation.isFinished
          @thread = NSThread.currentThread

          resume
        end

        @queue.addOperation(@operation)
        @operation.waitUntilFinished()
      end

      it "invokes the block within the provided context" do
        wait_max DELAY do
          @invoked_context.should == self
        end
      end

      it "invokes the block on the main thread" do
        wait_max DELAY do
          @thread.isMainThread.should.be.true
          @finished.should.be.true
        end
      end
    end

    describe "when the operation has been cancelled" do
      it "does not invoke the block" do
        @handler.on_completed do |operation|
          @invoked = true
        end

        @operation.cancel()

        @queue.addOperation(@operation)
        @operation.waitUntilFinished()

        wait DELAY do
          @invoked.should.be.nil
        end
      end
    end
  end

  describe "#on_started" do
    describe "when the operation has not been canceled" do
      before do
        @handler.on_started do |operation|
          @invoked_context = self
          @thread = NSThread.currentThread
          resume
        end
      end

      it "invokes the block within the provided context" do
        wait_max DELAY do
          @invoked_context.should == self
        end
      end

      it "invokes the block on the main thread after assigning it" do
        wait_max DELAY do
          @thread.isMainThread.should.be.true
        end
      end
    end

    describe "when the operation has been canceled" do
      it "does not invoke the block" do
        @handler.on_started do |operation|
          @invoked = true
        end

        @operation.cancel()

        wait DELAY do
          @invoked.should.be.nil
        end
      end
    end
  end
end
