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

        on_finish do |result, exception|
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

        on_finish do |name, exception|
          @result = name
          resume
        end
      end

      wait_max 1.0 do
        @result.should == "harry"
      end
    end

    it "allows tasks to report progress" do
      @updates = []

      async do
        task do
          sleep 0.1
          yield 1
          sleep 0.2
          yield 2
          sleep 0.3
          yield 3

          true
        end

        on_update do |count|
          @updates << count
        end

        on_finish do |result, exception|
          resume
        end
      end

      wait_max 1.0 do
        @updates.should == [1,2,3]
      end
    end
  end
end
