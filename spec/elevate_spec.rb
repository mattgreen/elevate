class TestController
  include Elevate

  def initialize
    @invocations = {}
    @counter = 0
    @threads = []
    @updates = []
  end

  attr_accessor :started
  attr_accessor :result
  attr_accessor :exception
  attr_accessor :invocations
  attr_accessor :counter
  attr_accessor :threads
  attr_accessor :updates

  task :test_task do
    task do
      sleep 0.05
      yield 1
      sleep 0.1
      yield 2

      42
    end

    on_start do
      self.invocations[:start] = counter
      self.counter += 1

      self.threads << NSThread.currentThread
    end

    on_update do |num|
      self.updates << num

      self.invocations[:update] = counter
      self.counter += 1

      self.threads << NSThread.currentThread
    end

    on_finish do |result, exception|
      self.invocations[:finish] = counter
      self.counter += 1

      self.threads << NSThread.currentThread

      self.result = result
      self.exception = exception

      #Dispatch::Queue.main.async { resume }
    end
  end
end

describe Elevate do
  extend WebStub::SpecHelpers

  before do
    @controller = TestController.new
  end

  describe "#launch" do
    it "runs the task asynchronously, returning the result" do
      @controller.launch(:test_task)

      wait 0.5 do
        @controller.result.should == 42
      end
    end

    it "allows tasks to report progress" do
      @controller.launch(:test_task)

      wait 0.5 do
        @controller.updates.should == [1, 2]
      end
    end

    it "invokes all callbacks on the UI thread" do
      @controller.launch(:test_task)

      wait 0.5 do
        @controller.threads.each { |t| t.isMainThread.should.be.true }
      end
    end

    it "invokes on_start before on_finish" do
      @controller.launch(:test_task)

      wait 0.5 do
        @controller.invocations[:start].should < @controller.invocations[:finish]
      end
    end

    it "invokes on_update before on_finish" do
      @controller.launch(:test_task)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:update].should < invocations[:finish]
      end
    end

    it "invokes on_update after on_start" do
      @controller.launch(:test_task)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:update].should > invocations[:start]
      end
    end
  end

  #describe "#async" do
    #describe "timeouts" do
      #before do
        #stub_request(:get, "http://example.com/").
          #to_return(body: "Hello!", content_type: "text/plain", delay: 1.0)
      #end

      #it "does not cancel the operation if it completes in time" do
        #@timed_out = false

        #async do
          #timeout 3.0

          #task do
            #Elevate::HTTP.get("http://example.com/")

            #"finished"
          #end

          #on_finish do |result, exception|
            #@result = result
            #resume
          #end
        #end

        #wait_max 5.0 do
          #@result.should == "finished"
          #@timed_out.should.be.false
        #end
      #end

      #it "stops the operation when timeout interval has elapsed" do
        #@result = nil

        #@task = async do
          #timeout 0.5

          #task do
            #Elevate::HTTP.get("http://example.com/")

            #"finished"
          #end

          #on_finish do |result, exception|
            #@result = result
            #resume
          #end
        #end

        #wait_max 5.0 do
          #@result.should.not == "finished"

          #@task.timed_out?.should.be.true
        #end
      #end

      #it "invokes on_timeout when a timeout occurs" do
        #@result = ""
        #@timed_out = false

        #async do
          #timeout 0.5

          #task do
            #Elevate::HTTP.get("http://example.com/")

            #"finished"
          #end

          #on_timeout do
            #@timed_out = true
          #end

          #on_finish do |result, exception|
            #@result = result
            #resume
          #end
        #end

        #wait_max 5.0 do
          #@result.should.not == "finished"
          #@timed_out.should.be.true
        #end
      #end
    #end
  #end
end
