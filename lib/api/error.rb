class API::Error < RuntimeError
  def as_json
    super.merge({'message' => message})
  end

  def to_xml
    node = LibXML::XML::Node.new('error')
    node << message = LibXML::XML::Node.new('message')
    message << LibXML::XML::Node.new_text(self.message)
    node
  end
end

class API::DBDownError < API::Error
  def as_json
    super.merge({'message' => 'server error'})
  end

  def to_xml
    node = LibXML::XML::Node.new('error')
    node << message = LibXML::XML::Node.new('message')
    message << LibXML::XML::Node.new_text('server error')
    node
  end
end

class API::NotFoundError < API::Error
  def message
    'not found'
  end
end

class API::ForbiddenError < API::Error
  def message
    'forbidden'
  end
end

class API::RateLimitError < API::Error
  def message
    'rate limit exceeded'
  end
end

class API::RecordMissingError < API::Error
  def message
    'record missing'
  end
end

class API::RecordInvalidError < API::Error
  def as_json
    super.merge({
      'message' => 'record invalid',
      'errors' => message
    })
  end

  def to_xml
    node = LibXML::XML::Node.new('error')
    node << message = LibXML::XML::Node.new('message')
      message << LibXML::XML::Node.new_text('record invalid')
    node << errors = LibXML::XML::Node.new('errors')
      errors << self.message.to_xml
    node
  end
end

class API::StatusError < API::Error
end
