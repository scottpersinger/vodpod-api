class Date
  def to_xml
    LibXML::XML::Node.new_text to_s
  end
end

class Exception
  case API.config.mode
  when :dev
    def to_xml
      node = LibXML::XML::Node.new('error')
      node << message = LibXML::XML::Node.new('message')
      message << LibXML::XML::Node.new_text(self.to_s)
      node << backtrace = LibXML::XML::Node.new('backtrace')
      backtrace << LibXML::XML::Node.new_text(self.backtrace.join("\n"))
      node
    end
  else
    def to_xml
      node = LibXML::XML::Node.new('error')
      node << message = LibXML::XML::Node.new('message')
      message << LibXML::XML::Node.new_text('server error')
      node
    end
  end
end

class FalseClass
  def to_xml
    LibXML::XML::Node.new('false')
  end
end

class LibXML::XML::Node
  def to_xml
    self
  end
end

class NilClass
  def to_xml
    nil
  end
end

class Numeric
  def to_xml
    LibXML::XML::Node.new_text(self.to_s)
  end
end

class String
  def to_xml
    LibXML::XML::Node.new_text(self)
  end
end

class Time
  def to_xml
    LibXML::XML::Node.new_text(self.iso8601)
  end
end

class TrueClass
  def to_xml
    LibXML::XML::Node.new('true')
  end
end

