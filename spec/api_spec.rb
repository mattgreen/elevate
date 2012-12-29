module Bacon
  class Context
    include Arbiter::Support
  end
end

describe Arbiter::Support do
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
