module Bacon
  class Context
    include ::Elevate
  end
end

describe Elevate do
  describe "#async" do
    it "runs the specified interactor asynchronously" do

      async Target.new() do
        on_completed do |operation|
          @called = true
          resume
        end
      end

      wait_max 1.0 do
        @called.should.be.true
      end
    end
  end
end
