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
          true
        end

        on_completed do |result, exception|
          @called = result
          resume
        end
      end

      wait_max 1.0 do
        @called.should.be.true
      end
    end

    it "passes provided args to the task as instance variables" do
      async name: "harry" do
        task do
          @name
        end

        on_completed do |name, exception|
          @result = name
          resume
        end
      end

      wait_max 1.0 do
        @result.should == "harry"
      end
    end
  end
end
