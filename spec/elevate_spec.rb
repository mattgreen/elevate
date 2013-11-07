class TestController
  include Elevate

  def initialize
    @invocations = {}
    @counter = 0
    @threads = []
    @updates = []
    @callback_args = nil
  end

  attr_accessor :started
  attr_accessor :result
  attr_accessor :exception
  attr_accessor :invocations
  attr_accessor :counter
  attr_accessor :threads
  attr_accessor :updates
  attr_accessor :callback_args

  task :cancellable do
    task do
      task_args[:semaphore].wait
      yield 42

      nil
    end

    on_start do
      self.invocations[:start] = counter
      self.counter += 1
    end

    on_finish do |result, ex|
      self.invocations[:finish] = counter
      self.counter += 1
    end

    on_update do |n|
      self.invocations[:update] = counter
      self.counter += 1
    end
  end

  task :custom_error_handlers do
    task do
      raise TimeoutError
    end

    on_error do |e|
      self.invocations[:error] = counter
      self.counter += 1
    end

    on_timeout do |e|
      self.invocations[:timeout] = counter
      self.counter += 1
    end
  end

  task :test_task do
    task do
      sleep 0.05
      yield 1
      raise Elevate::TimeoutError if task_args[:raise]
      sleep 0.1
      yield 2

      42
    end

    on_start do
      self.invocations[:start] = counter
      self.callback_args = task_args
      self.counter += 1

      self.threads << NSThread.currentThread
    end

    on_update do |num|
      self.updates << num

      self.invocations[:update] = counter
      self.counter += 1

      self.threads << NSThread.currentThread
    end

    on_error do |e|
      self.invocations[:error] = counter
      self.counter += 1
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

  task :timeout_test do
    timeout 0.3

    task do
      Elevate::HTTP.get("http://example.com/")
    end

    on_timeout do |e|
      self.invocations[:timeout] = counter
      self.counter += 1
    end

    on_finish do |result, ex|
      self.invocations[:finish] = counter
      self.counter += 1
    end
  end
end

describe Elevate do
  extend WebStub::SpecHelpers

  before do
    @controller = TestController.new
  end

  describe "#cancel" do
    describe "when no tasks are running" do
      it "does nothing" do
        ->{ @controller.cancel(:test_task) }.should.not.raise
      end
    end

    describe "when a single task is running" do
      it "cancels the task and does not invoke callbacks" do
        semaphore = Dispatch::Semaphore.new(0)
        @controller.launch(:cancellable, semaphore: semaphore)

        @controller.cancel(:cancellable)
        semaphore.signal

        wait 0.5 do
          @controller.invocations[:update].should.be.nil
          @controller.invocations[:finish].should.be.nil
        end
      end
    end

    describe "when several tasks are running" do
      it "cancels all of them" do
        semaphore = Dispatch::Semaphore.new(0)

        @controller.launch(:cancellable, semaphore: semaphore)
        @controller.launch(:cancellable, semaphore: semaphore)
        @controller.launch(:cancellable, semaphore: semaphore)

        @controller.cancel(:cancellable)
        semaphore.signal

        wait 0.5 do
          @controller.invocations[:update].should.be.nil
          @controller.invocations[:finish].should.be.nil
        end

      end
    end
  end

  describe "#launch" do
    it "runs the task asynchronously, returning the result" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        @controller.result.should == 42
      end
    end

    it "allows tasks to report progress" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        @controller.updates.should == [1, 2]
      end
    end

    it "invokes all callbacks on the UI thread" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        @controller.threads.each { |t| t.isMainThread.should.be.true }
      end
    end

    it "sets task_args to args used at launch" do
      @controller.launch(:test_task, raise: true)

      wait 0.5 do
        @controller.callback_args.should == { raise: true }
      end
    end

    it "invokes on_error when an exception occurs" do
      @controller.launch(:test_task, raise: true)

      wait 0.5 do
        @controller.invocations[:error].should.not.be.nil
      end
    end

    it "invokes on_start before on_finish" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        @controller.invocations[:start].should < @controller.invocations[:finish]
      end
    end

    it "invokes on_update before on_finish" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:update].should < invocations[:finish]
      end
    end

    it "invokes on_update after on_start" do
      @controller.launch(:test_task, raise: false)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:update].should > invocations[:start]
      end
    end
  end

  describe "error handling" do
    it "invokes an error handling correspding to the raised exception" do
      @controller.launch(:custom_error_handlers)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:timeout].should.not.be.nil
        invocations[:error].should.be.nil
      end
    end

    it "invokes on_error if there is not a specific handler" do
      @controller.launch(:test_task, raise: true)

      wait 0.5 do
        invocations = @controller.invocations

        invocations[:error].should.not.be.nil
      end
    end
  end

  describe "timeouts" do
    it "does not cancel the operation if it completes in time" do
      stub_request(:get, "http://example.com/").
        to_return(body: "Hello!", content_type: "text/plain")

      @controller.launch(:timeout_test)

      wait 0.5 do
        @controller.invocations[:timeout].should.be.nil
        @controller.invocations[:finish].should.not.be.nil
      end
    end

    it "stops the operation when it exceeds the timeout" do
      stub_request(:get, "http://example.com/").
        to_return(body: "Hello!", content_type: "text/plain", delay: 1.0)

      @controller.launch(:timeout_test)

      wait 0.5 do
        @controller.invocations[:finish].should.not.be.nil
      end
    end

    it "invokes on_timeout when the operation times out" do
      stub_request(:get, "http://example.com/").
        to_return(body: "Hello!", content_type: "text/plain", delay: 1.0)

      @controller.launch(:timeout_test)

      wait 0.5 do
        @controller.invocations[:timeout].should.not.be.nil
      end

    end
  end
end
