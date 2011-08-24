class API::MainController
  # List videos
  cache_with PAGE_CACHE_KEYS + RECORD_CACHE_KEYS + TAG_CACHE_KEYS
  h 'videos' do
    if request['tags'].blank?
      raise API::ForbiddenError, 'you may only list videos belonging to specific tags'
    end
    
    API.videos(request.params)
  end
end
