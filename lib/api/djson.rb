class API::DJSON
  def initialize(str)
    @json = str
  end

  def to_json
    @json
  end
end
