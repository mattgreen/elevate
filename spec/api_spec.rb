module Bacon
  class Context
    include Interactor::Support
  end
end

describe Interactor::Support do
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
