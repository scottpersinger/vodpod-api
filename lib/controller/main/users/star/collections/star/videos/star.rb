class API::MainController
  # A particular video in a collection
  cache_with RECORD_CACHE_KEYS
  h 'users', :*, 'collections', :*, 'videos', :* do |user, collection, video|  
    API.video(user, collection, video, request.params)
  end
end
