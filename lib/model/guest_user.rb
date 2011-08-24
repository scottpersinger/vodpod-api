class Vodpod::GuestUser
  plugin :serialize
  plugin :xml
  plugin :json

  attr :website, :default => true, :include => true
  attr :name, :default => true, :include => true
end
