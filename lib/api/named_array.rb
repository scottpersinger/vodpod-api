class NamedArray
  # Because XML arrays need to have an enclosing named node, we use this class.
  
  attr_accessor :data
  attr_accessor :total
  attr_accessor :unread
  attr_accessor :name

  def name
    @name ||= 'results'
  end

  def initialize(name, data)
    @data = data
    @name = name
  end

  def as_json
    data = @data.map do |e|
      if e.respond_to? :to_hash
        e.to_hash
      else
        e
      end
    end

    h = {:results => data}
    h[:total] = @total if @total
    h[:unread] = @unread if @unread
    h
  end

  def to_xml
    root = LibXML::XML::Node.new(name)
    root['total'] = total.to_s if total
    root['unread'] = unread.to_s if unread
    @data.each do |i|
      root << i.to_xml
    end
    root
  end

  def to_json(*a)
    as_json.to_json(*a)
  end
  
  def to_hash
    data = @data.map do |e|
      if e.respond_to? :to_hash
        e.to_hash
      else
        e
      end
    end

    {:total => total, :results => data}
  end
    
end
