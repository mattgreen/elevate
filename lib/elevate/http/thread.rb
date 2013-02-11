module Elevate
module HTTP
  class NetworkThread
    def self.cancel(connection)
      connection.performSelector(:cancel, onThread:thread, withObject:nil, waitUntilDone:false)
    end

    def self.start(connection)
      connection.performSelector(:start, onThread:thread, withObject:nil, waitUntilDone:false)
    end

    private

    def self.main(_)
      while true
        NSRunLoop.currentRunLoop.run
      end
    end

    def self.thread
      Dispatch.once do
        @thread = NSThread.alloc.initWithTarget(self, selector: :"main:", object: nil)
        @thread.start
      end

      @thread
    end
  end
end
end
