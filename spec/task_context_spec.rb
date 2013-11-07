describe Elevate::TaskContext do
  describe "#execute" do
    it "runs the specified block" do
      result = {}

      context = Elevate::TaskContext.new(->{ result[:ret] = true }, {})
      context.execute

      result[:ret].should.be.true
    end
  end
end
