class Vodpod::Category
  plugin :serialize
  plugin :xml
  plugin :json

#  attr :daily_count
#  attr :total_count
  attr :key, :columns => [:name], :default => true, :include => true
  attr :name, :default => true, :include => true
  attr :top_users, :default => true, :include => false
  attr :recommended_users, :default => true, :include => false
#  attr :videos, :default => true
  association_attr :subcategories
end
