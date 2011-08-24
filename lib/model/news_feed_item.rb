class Vodpod::NewsFeedItem
  plugin :serialize
  plugin :xml
  plugin :json

  attr :action, :default => true, :include => true
#  association_attr :collection_audit, :default => true, :include => true
  association_attr :collection_video
  attr :created_at, :default => true, :include => true
  association_attr :group, :default => true, :include => true
  association_attr :guest_user, :default => true, :include => true
  attr :key, :order => [:id], :default => true, :include => true
  association_attr :owner
  association_attr :tag, :default => true, :include => true
  attr :text, :default => true, :include => true
  association_attr :user, :default => true, :include => true
  association_attr :user2, :default => true, :include => true
  association_attr :video, :default => true, :include => true

  filterable :ios

  def_dataset_method :ios do
    filter(:supports_ios)
  end

  def key
    self[:id]
  end
end
