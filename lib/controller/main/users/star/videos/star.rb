class API::MainController
  # Select a particular video for a user.
  cache_with RECORD_CACHE_KEYS
  h 'users', :*, 'videos', :* do |user, video|
    API.video(user, video, request.params)
  end
end
