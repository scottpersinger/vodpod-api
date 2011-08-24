module API
  # Require vodpod-common models
  require 'vodpod/model'

  # Plugins
  require 'model/plugins/serialize'
  require 'model/plugins/xml'
  require 'model/plugins/json'

  # Extend vodpod models
  require 'model/category'
  require 'model/comment'
  require 'model/news_feed_item'
  require 'model/user'
  require 'model/guest_user'
  require 'model/group'
  require 'model/collection'
  require 'model/tag'
  require 'model/collection_video'
  require 'model/collection_video_comment'
  require 'model/video'

  # Alias model classes
  Category                = Vodpod::Category
  Comment                 = Vodpod::Comment
  Collection              = Vodpod::Collection
  CollectionVideo         = Vodpod::CollectionVideo
  Group                   = Vodpod::Group
  GuestUser               = Vodpod::GuestUser
  NewsFeedItem            = Vodpod::NewsFeedItem
  Tag                     = Vodpod::Tag
  User                    = Vodpod::User
  Video                   = Vodpod::Video
  VideoTagging            = Vodpod::Video
  CollectionVideoTagging  = Vodpod::CollectionVideoTagging
  CollectionVideoComment  = Vodpod::CollectionVideoComment
end
