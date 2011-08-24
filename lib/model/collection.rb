class Vodpod::Collection
  plugin :serialize
  plugin :xml
  plugin :json
  
  association_reflection(:tags)[:limit] = API.config.include_tags_limit
  association_reflection(:videos)[:limit] = API.config.include_tags_limit

  # Attributes
  attr :created_at, :order => [:created_at]
  attr :description, :default => true
  attr :key, :columns => [:subdomain], :default => true, :include => true, :order => [:subdomain]
  attr :name, :columns => [:name], :default => true, :include => true, :order => [:name]
  association_attr :tags
  attr :thumbnail
  attr :total_views, :order => [:total_views]
  attr :updated_at, :order => [:updated_at]
  attr :url, :columns => [:subdomain], :associations => [:user]
  association_attr :user
  association_attr :videos
  attr :videos_count, :columns => [:groupvideos_count], :default => true, :order => [:videos_count]
  attr :weekly_views, :order => [:weekly_views]

  # Dataset of the default collection for a username.
  def_dataset_method :default_for do |user|
    Vodpod::User.api_get(user).first.collection_dataset
  end

  # Returns a dataset of all collections belonging to a username.
  def_dataset_method :belonging_to do |user|
    if u = Vodpod::User.api_get(user).first
      u.collections_dataset
    else
      raise API::RecordMissingError, "user (#{user}) does not exist"
    end
  end

  def url
    "#{API.config.site.vodpod_url}/#{user.name}/#{key}"
  end
end
