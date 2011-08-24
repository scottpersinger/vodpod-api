class API::MainController
  # Video comments
  cache_with PAGE_CACHE_KEYS + RECORD_CACHE_KEYS
  h 'users', :*, 'collections', :*, 'videos', :*, 'comments' do |user, collection, video|
    API.comments(video, request.params)
  end
end
