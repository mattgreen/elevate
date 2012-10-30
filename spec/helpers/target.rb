class Target
  attr_reader   :called
  attr_accessor :exception
  attr_accessor :result

  def initialize
    @called = 0
    @result = true
  end

  def execute
    @called += 1

    if @exception
      raise @exception
    end

    @result
  end
end
