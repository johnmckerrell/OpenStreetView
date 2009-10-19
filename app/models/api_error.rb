class APIError < StandardError
  attr_reader :code

  def initialize(message,code=400)
    @code = code
    super(message)
  end
end
