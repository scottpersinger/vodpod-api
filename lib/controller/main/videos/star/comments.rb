class API::MainController
  # Comments on a video
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS
  h 'videos', :*, 'comments' do |video|
    API.comments(video, request.params)
  end
end
