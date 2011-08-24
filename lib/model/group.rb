class Vodpod::Group
  plugin :xml
  plugin :json
  plugin :serialize

  attr :key, :default => true, :include => true
  attr :title, :default => true, :include => true
  attr :created_at, :default => true
  attr :updated_at, :default => true

  def key
    self[:url_title]
  end
end
