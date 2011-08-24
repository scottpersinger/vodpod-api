class NamedHash < Hash
  # Because XML hashes need to have an enclosing named node, we use this class.
  
  attr_accessor :name

  def name
    @name ||= 'results'
  end

  def initialize(name, data)
    super()
    @name = name
    self.replace data
  end

  def to_xml
    root = LibXML::XML::Node.new(name)
    each do |k,v|
      node = LibXML::XML::Node.new(k.to_s)
      node << v.to_xml
      root << node
    end
    root
  end
end
