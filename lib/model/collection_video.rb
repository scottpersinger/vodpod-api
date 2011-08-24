class Vodpod::CollectionVideo
  plugin :serialize
  plugin :xml
  plugin :json

  association_reflection(:collection_comments)[:limit] = API.config.include_limit
  association_reflection(:comments)[:limit] = API.config.include_limit

  # Attributes
  attr :autoplay_embed, :associations => [:video], :default => true
  attr :created_at, :default => true, :include => true, :order => [:created_at]
  # Eager loading is still broken.
  association_attr :comments, :default => false
  attr :collected_from_url, :columns => [:rss_from, :external_url]
  association_attr :collection
  association_attr :collection_comments, :default => false
  attr :collections_count, :associations => [:video]
  attr :description, :default => true, :columns => [:comment]
  attr :embed, :default => true, :include => true, :columns => [:group_id], :associations => [:video]
  attr :embed_src, :default => false, :include => false, :columns => [], :associations => [:video]
  attr :key, :columns => [:video_id], :default => true, :include => true, :order => [:video_id]
  attr :media, :columns => [:video_id], :default => true, :include => true
  attr :media_240_mobile, :columns => [:video_id], :default => true, :include => true
  attr :media_480_web, :columns => [:video_id], :default => true, :include => true
  attr :recommends, :associations => [:video], :default => true, :include => true
  attr :ranking, :default => false, :include => false, :order => [:ranking.desc, :created_at.desc]
  association_attr :tags
  attr :thumbnail, :default => true, :include => true, :columns => [], :associations => [:video]
  attr :thumbnail_80, :associations => [:video]
  attr :thumbnail_160, :associations => [:video]
  attr :thumbnail_320, :associations => [:video]
  attr :title, :default => true, :include => true, :order => [:title]
  attr :total_views, :default => true, :order => [:total_views]
  attr :total_external_views, :order => [:total_external_views]
  attr :url, :associations => [:user, :video, :collection], :columns => [], :default => true, :include => true
  association_attr :user
  attr :video_host, :columns => [:description], :default => true, :associations => [:video]
  attr :weekly_views, :order => [:weekly_views]

  filterable :ios

  # Gets videos belonging to a user.
  def_dataset_method :belonging_to do |user|
    Vodpod::User.api_get(user).first.videos_dataset
  end

  # Gets videos from a user name and collection name.
  def_dataset_method :in_collection do |user, collection|
    if u = Vodpod::User.api_get(user).first
      if c = u.collections_dataset.api_get(collection).first
        c.videos_dataset
      else
        raise API::RecordMissingError, "collection (#{collection}) does not exist"
      end
    else
      raise API::RecordMissingError, "user (#{user}) does not exist"
    end
  end

  def_dataset_method :ios do
    filter(:supports_ios)
  end

  # Our embeds always come with a tracker attached.
  def autoplay_embed
    "#{video.__autoplay_embed__}#{tracker(true)}"
  end

  # Our embeds always come with a tracker attached.
  def embed
    "#{video.__embed__}#{tracker(true)}"
  end
end
