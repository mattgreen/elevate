module Bacon
  class Context
    include ::Elevate
  end
end

describe Elevate do
  describe "#async" do
    it "runs the specified task asynchronously" do

      async do
        task do
          sleep 0.3
          @called = true
        end

        on_completed do |operation|
          resume
        end
      end

      wait_max 1.0 do
        @called.should.be.true
      end
    end
  end
end
