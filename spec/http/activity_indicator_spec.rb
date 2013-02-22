describe Elevate::HTTP::ActivityIndicator do
  before do
    UIApplication.sharedApplication.setNetworkActivityIndicatorVisible(false)

    @indicator = Elevate::HTTP::ActivityIndicator.new
  end

  describe ".instance" do
    it "returns a singleton instance" do
      instance = Elevate::HTTP::ActivityIndicator.instance
      instance2 = Elevate::HTTP::ActivityIndicator.instance

      instance.object_id.should == instance2.object_id
    end
  end

  describe "#hide" do
    it "does nothing if it isn't shown" do
      @indicator.hide

      UIApplication.sharedApplication.isNetworkActivityIndicatorVisible.should.be.false
    end

    it "hides the indicator only if there are no outstanding show requests" do
      @indicator.show

      @indicator.show
      @indicator.hide

      UIApplication.sharedApplication.isNetworkActivityIndicatorVisible.should.be.true

      @indicator.hide
      UIApplication.sharedApplication.isNetworkActivityIndicatorVisible.should.be.false
    end
  end

  describe "#show" do
    it "shows the activity indicator" do
      @indicator.show

      UIApplication.sharedApplication.isNetworkActivityIndicatorVisible.should.be.true
    end
  end
end
