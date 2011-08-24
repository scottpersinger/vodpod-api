module Ramaze::Helper::Parse
  def parse_range(str)
    return nil if str.nil?
    str =~ /^((\d+)((\.\.\.?)(\d+))?)?$/ or raise API::Error, 'invalid range'
    
    if $2.nil?
      raise API::Error, 'invalid range'
    end

    i1 = $2.to_i

    if $5.nil?
      return i1..i1
    end

    i2 = $5.to_i

    if $4 == '...'
      i1...i2
    else
      i1..i2
    end
  end
end
