class API::MainController
  # A specific video
  cache_with RECORD_CACHE_KEYS
  h 'videos', :* do |video|
    API.video(video, request.params)
  end
end
