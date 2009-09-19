class APIError < StandardError
  attr_reader :code

  def initialize(message,code=nil)
    @code = code
    super(message)
  end
end
