class Vodpod::Tag
  plugin :serialize
  plugin :xml
  plugin :json

  association_reflection(:collection_videos)[:limit] = API.config.include_limit
  association_reflection(:videos)[:limit] = API.config.include_limit
  association_reflection(:collections)[:limit] = API.config.include_limit
  association_reflection(:users)[:limit] = API.config.include_limit

  # Attributes
  attr :key, :columns => [:name], :default => true, :include => true
  attr :name, :default => true, :include => true
  association_attr :collection_videos
  association_attr :collections
  attr :count
  association_attr :users
  association_attr :videos
end
