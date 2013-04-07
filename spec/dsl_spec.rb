describe Elevate::DSL do
  describe "#on_started" do
    it "stores the provided block" do
      i = Elevate::DSL.new do
        on_started { puts 'hi' }
      end

      i.started_callback.should.not.be.nil
    end
  end

  describe "#on_completed" do
    it "stores the passed block" do
      i = Elevate::DSL.new do
        on_completed { |result, exception| puts 'hi' }
      end

      i.finished_callback.should.not.be.nil
    end
  end
end
