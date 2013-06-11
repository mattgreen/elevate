module Bacon
  class Context
    include ::Elevate
  end
end

describe Elevate do
  extend WebStub::SpecHelpers

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

    describe "timeouts" do
      before do
        stub_request(:get, "http://example.com/").
          to_return(body: "Hello!", content_type: "text/plain", delay: 1.0)
      end

      it "does not cancel the operation if it completes in time" do
        @timed_out = false

        async do
          timeout 3.0

          task do
            Elevate::HTTP::HTTPClient.new("http://example.com/").get("")

            "finished"
          end

          on_finish do |result, exception|
            @result = result
            resume
          end
        end

        wait_max 5.0 do
          @result.should == "finished"
          @timed_out.should.be.false
        end
      end

      it "stops the operation when timeout interval has elapsed" do
        task = async do
          timeout 0.5

          task do
            Elevate::HTTP::HTTPClient.new("http://example.com/").get("")

            "finished"
          end

          on_finish do |result, exception|
            @result = result
            resume
          end
        end

        wait_max 5.0 do
          @result.should.not == "finished"

          task.timed_out?.should.be.true
        end
      end

      it "invokes on_timeout when a timeout occurs" do
        @result = ""
        @timed_out = false

        async do
          timeout 0.5

          task do
            Elevate::HTTP::HTTPClient.new("http://example.com/").get("")

            "finished"
          end

          on_timeout do
            @timed_out = true
          end

          on_finish do |result, exception|
            @result = result
            resume
          end
        end

        wait_max 5.0 do
          @result.should.not == "finished"
          @timed_out.should.be.true
        end
      end
    end
  end
end
