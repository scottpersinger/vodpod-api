# Shared API functions. The core of the API.
module API
  # Returns a specific collection by user and collection name.
  # If collection is the symbol :default (as opposed to a string), calls
  # default_collection instead.
  def self.collection(user_key, collection_key, params = {})
    if collection_key == :default
      return default_collection(user_key, params)
    end

    # Otherwise, find the collection by name.
    collection = Collection.belonging_to(user_key).api_get(collection_key).api_filter(params).first
    if collection.nil?
      raise API::Error.new("collection (#{collection_key}) does not exist")
    end
    collection
  end

  # Returns an array of collections for a user.
  def self.collections(user, params = {})
    collections = Collection.belonging_to(user).limit(10).order(:groups__subdomain).api_filter(params)
    a = NamedArray.new('collections', collections.all)
    a.total = collections.unlimited.select(:groups__id).count
    a
  end

  # Returns collection_comments on a video, by key. Eager-loads users for the
  # comments.
  def self.collection_comments(user, collection, video, params = {})
    # TODO: remove this default fetch by pushing it into Collection.api_get?
    if collection == :default
      collection = User.api_get(user).first.collection.key
    end
    comments = CollectionVideoComment.on(user, collection, video).limit(10).order(:created_at.desc).api_filter(params).eager(:user)
    a = NamedArray.new('comments', comments.all)
    a.total = comments.unlimited.select(:group_audits__id).count
    a
  end

  # Returns comments on a video, by key. Eager-loads users for the comments.
  def self.comments(video, params = {})
    comments = Comment.on(video).limit(10).order(:created_at.desc).api_filter(params).eager(:user)
    a = NamedArray.new('comments', comments.all)
    a.total = comments.unlimited.select(:group_audits__id).count
    a
  end

  # Returns the default collection for the given user.
  def self.default_collection(user, params = {})
    collection = Collection.default_for(user).api_filter(params).first
    if collection.nil?
      raise API::Error, "No default collection for user (#{user})"
    end
    collection
  end

  # Searches for things
  # Params:
  #   collection => the collection name to search in.
  #   user => the user name to search in.
  #   
  def self.search(query, params= {})
    raise API::Error, "no query given for search" if query.blank?

    # Parameters
    params = API.preprocess params
    defaults = {}
    if params['user']
      defaults['type'] = 'collection_video'
    else
      defaults['type'] = 'video'
    end
    params = defaults.merge params
   
    # What collection are we searching for?
    if collection = params['collection'] and user = params['user']
      # Search in a particular collection
      if collection == :default
        params['collection_ids'] = [User.api_get(user).first.select(:default_group_id).default_group_id]
      else
        params['collection_ids'] = [Collection.belonging_to(user).api_get(collection).select(:groups__id).first.id]
      end
    elsif user = params['user']
      # Search in all collections for a user
      params['collection_ids'] = Collection.belonging_to(user).map(:id)
    end

    # Search!
    begin
      API.searcher.search query, params
    rescue Errno::ECONNREFUSED => e
      raise API::Error, 'search service unavailable'
    end
  end

  # Returns a specific user by key.
  def self.user(user_key, params = {})
    user = User.api_get(user_key).api_filter(params).first
    if user.nil?
      raise API::RecordMissingError, "user (#{user_key}) does not exist"
    end
    user
  end

  # Returns a list of users.
  def self.users(params = {})
    users = User.limit(10).order(:users__created_at.desc).api_filter(params)
    a = NamedArray.new('users', users.all)
    a.total = users.unlimited.select(:users__id).count
    a
  end

  # Returns a video. Three cases:
  #
  # video(aphyr, frisbee, 12343, opts = {}) => A CollectionVideo
  # video(aphyr, 13423, opts = {}) => A CollectionVideo
  # video(13423, opts = {}) => A Video
  def self.video(*args)
    if args.last.kind_of? Hash
      params = args.pop
    else
      params = {}
    end

    if args.size == 1
      # Get a Video
      video = Video.api_get(args[0]).api_filter(params).first
      if video.nil?
        raise API::RecordMissingError.new("video (#{args.last}) does not exist")
      end
    elsif args.size == 2
      # Get a video for a user
      video = CollectionVideo.belonging_to(args[0]).api_get(args[1]).api_filter(params).first
      if video.nil?
        raise API::RecordMissingError.new("Video (#{args.last}) has not been collected by user (#{args[0]})")
      end
    elsif args.size == 3
      # Get a video in a user's collection
      if args[1] == :default
        # Find in the user's default collection
        video = User.api_get(args[0]).collection.videos_dataset.api_get(args[2]).api_filter(params).first
      else
        # Find in an arbitrary collection
        video = CollectionVideo.in_collection(args[0], args[1]).api_get(args[2]).api_filter(params).first
      end

      if video.nil?
        raise API::RecordMissingError.new("video (#{args.last}) does not exist in collection (#{args[0]}/#{args[1]})")
      end
    else
      raise ArgumentError.new('video() takes either one or three arguments, plus an optional parameter hash.')
    end
    
    video
  end


  # Returns a list of videos. Three cases:
  #
  # videos(aphyr, frisbee, opts = {}) => A list of CollectionVideos in a collection named frisbee belonging to aphyr.
  # videos(aphyr, opts = {}) => A list of CollectionVideos in collections belonging to the user named aphyr.
  # videos(opts = {}) => A list of Videos
  def self.videos(*args)

    if args.last.kind_of? Hash
      params = args.pop
    else
      params = {}
    end

    params = preprocess params

    if args.size == 0
      # Get videos
      # You can't use order on this path any more.
      if params['sort']
        raise API::Error, 'sorting is not allowed for this path'
      end
      videos = Video.limit(10).order(:video_taggings__record_created_at.desc).api_filter(params)
      count = videos.all.size #videos.select(:videos__id).unlimited.count
      count += 1 if count > 0

      # Construct result set
      a = NamedArray.new('videos', videos.all)
      a.total = count

    elsif args.size == 1
      videos = CollectionVideo.belonging_to(args[0]).order(:groupvideos__created_at.desc).api_filter(params)
      count = videos.select(:groupvideos__id).unlimited.count
      a = NamedArray.new('videos', videos.all)
      a.total = count
    elsif args.size == 2
      if args[1] == :default
        videos = User.api_get(args[0]).first.collection.videos_dataset.api_filter(params)
        count = videos.select(:groupvideos__id).unlimited.count
      else
        videos = CollectionVideo.in_collection(args[0], args[1]).order(:groupvideos__created_at.desc).api_filter(params)
        count = videos.select(:groupvideos__id).unlimited.count
      end
      a = NamedArray.new('videos', videos.all)
      a.total = count
    else
      raise ArgumentError.new('videos() takes either zero, one, or two arguments, plus an optional parameter hash.')
    end

    a
  end

  # Returns the number of videos associated with various objects.
  #   videos_count(:user => user, :collection => collection, :tag => tag)
  def self.videos_count(params)
    params = preprocess params

    collection = params['collection']
    user = params['user']
    tag  = params['tag']

    if collection and tag and user
      c = Collection.belonging_to(user).api_get(collection).select(:user_id, :id).first
      c.tags_dataset.filter(:name => tag).unlimited.count
    elsif collection and user
      Collection.belonging_to(user).api_get(collection).select(:id, :groupvideos_count).first.videos_count
    elsif tag and user
      u = User.api_get(user).select(:id).first
      u.tags_dataset.filter(:name => tag).unlimited.count
    elsif user
      User.api_get(user).select(:id, :groupvideos_count).first.videos_count
    elsif tag
      Tag.api_get(tag).first.videos_count
    else
      raise Error, "unknown parameters for videos_count (#{videos_count.keys.join(', ')})"
    end
  end

  # Called by api_filter
  unless respond_to? :preprocess
    def self.preprocess(params)
      params
    end
  end
end
