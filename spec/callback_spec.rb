describe Interactor::Callback do
  describe "#call" do
    it "invokes the block using instance_*" do
      callback = Interactor::Callback.new(self, 42, lambda { |v| @value = v })
      callback.call

      @value.should == 42
    end

  end
end

