class Vodpod::Comment
  plugin :serialize
  plugin :xml
  plugin :json

  attr :key, :default => true, :include => true
  attr :text, :default => true, :include => true
  attr :created_at, :default => true, :include => true, :order => [:created_at]
  attr :user, :default => true, :include => true, :associations => [:user], :columns => [:guest_user_id]

  def key
    id
  end
end
