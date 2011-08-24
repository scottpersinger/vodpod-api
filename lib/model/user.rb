class Vodpod::User
  plugin :serialize
  plugin :xml
  plugin :json
 
  association_reflection(:discovered_videos)[:limit] = API.config.include_limit
  association_reflection(:videos)[:limit] = API.config.include_limit
  association_reflection(:tags)[:limit] = API.config.include_limit
  association_reflection(:following)[:limit] = API.config.include_limit
  association_reflection(:following)[:order] = :last_login.desc
  association_reflection(:followers)[:limit] = API.config.include_limit
  association_reflection(:followers)[:order] = :last_login.desc

  # Attributes
  association_attr :collection
  association_attr :collections
  attr :created_at, :order => [:created_at]
  attr :description, :default => true
  association_attr :discovered_videos
  attr :feed_checked_at, :default => true, :include => false
  association_attr :followers
  association_attr :following
  attr :key, :order => [:simple_name], :columns => [:simple_name], :default => true, :include => true
  attr :name, :columns => [:name], :default => true, :include => true
  attr :points, :columns => [:karma], :default => true, :include => true
  association_attr :tags
  attr :thumbnail, :columns => [:image], :default => true, :include => true
  attr :updated_at, :order => [:updated_at]
  attr :url, :columns => [:simple_name]
  attr :urls, :columns => [:url1, :url2]
  association_attr :videos
  attr :videos_count, :columns => [:groupvideos_count], :default => true

  def url
    "#{API.config.site.vodpod_url}/#{key}"
  end
end
