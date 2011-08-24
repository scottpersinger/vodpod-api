class API::MainController
  # All videos in a collection
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS + TAG_CACHE_KEYS
  h 'users', :*, 'collections', :*, 'videos' do |user, collection|
    API.videos(user, collection, request.params)
  end
end
