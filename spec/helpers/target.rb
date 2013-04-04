class Target
  attr_reader   :called
  attr_reader   :io_coordinator
  attr_accessor :exception
  attr_accessor :result

  def initialize
    @called = 0
    @result = true
  end

  def call
    @io_coordinator = Thread.current[:io_coordinator]

    @called += 1

    if @exception
      raise @exception
    end

    @result
  end
end
