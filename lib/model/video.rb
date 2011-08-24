class Vodpod::Video
  plugin :serialize
  plugin :xml
  plugin :json

  association_reflection(:collection_videos)[:limit] = API.config.include_limit
  association_reflection(:collections)[:limit] = API.config.include_limit
  association_reflection(:comments)[:limit] = API.config.include_limit
  association_reflection(:users)[:limit] = API.config.include_limit
  association_reflection(:tags)[:limit] = API.config.include_limit
 
  # Attributes
  attr :autoplay_embed, :default => true
  attr :created_at, :default => true, :include => true, :order => [:created_at]
  association_attr :collections
  attr :collections_count, :columns => [:groupvideos_count]
  association_attr :collection_videos
  association_attr :comments, :default => false
  attr :description, :default => true, :columns => [:comment]
  attr :embed, :columns => [:embed_tag, :primary_groupvideo_id], :default => true, :include => true
  attr :embed_src, :columns => [:embed_tag], :default => false, :include => false
  attr :key, :columns => [:id], :default => true, :include => true, :order => [:ey]
  attr :media, :columns => [:flv_media], :default => true, :include => true
  attr :media_240_mobile, :columns => [:flv_media], :default => true, :include => true
  attr :media_480_web, :columns => [:flv_media], :default => true, :include => true
  attr :recommends, :columns => [:up_votes_count], :default => true, :include => true
  association_attr :tags
  attr :thumbnail, :columns => [:thumbnail], :default => true, :include => true
  attr :thumbnail_80, :columns => [:thumbnail]
  attr :thumbnail_160, :columns => [:thumbnail]
  attr :thumbnail_320, :columns => [:thumbnail]
  attr :title, :default => true, :include => true, :order => [:title]
  attr :total_views, :default => true, :order => [:total_views]
  attr :total_external_views, :order => [:total_external_views]
  attr :updated_at, :order => [:updated_at]
  attr :url, :columns => [:orig_title, :title, :id], :default => true, :include => true
  association_attr :users
  attr :collection_videos_count, :default => true, :include => false
  attr :video_host, :default => true, :columns => [:description, :media]
  attr :weekly_views, :order => [:weekly_views]

  # Our embeds always come with a tracker attached.
  def autoplay_embed
    "#{__autoplay_embed__}#{tracker(true)}"
  end

  alias :__embed__ :embed
  def embed
    "#{__embed__}#{tracker(true)}"
  end

  def url
    "#{API.config.site.vodpod_url}/watch/#{key}-#{url_title}"
  end
end
