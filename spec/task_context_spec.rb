describe Elevate::TaskContext do
  describe "#execute" do
    it "runs the specified block" do
      result = {}

      context = Elevate::TaskContext.new(->{ result[:ret] = true }, {})
      context.execute

      result[:ret].should.be.true
    end

    it "has ivars set from the arg hash passed into #initialize" do
      result = {}

      context = Elevate::TaskContext.new(->{ result[:ret] = @secret }, { secret: 18 })
      context.execute

      result[:ret].should == 18
    end
  end
end
