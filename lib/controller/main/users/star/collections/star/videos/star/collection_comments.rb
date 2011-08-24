class API::MainController
  # Collection comments
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS
  h 'users', :*, 'collections', :*, 'videos', :*, 'collection_comments' do |user_key, collection_key, video_key|
    API.collection_comments(user_key, collection_key, video_key, request.params)
  end
end
