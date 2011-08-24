class API::MainController
  # Show a specific user.
  cache_with RECORD_CACHE_KEYS
  h 'users', :* do |user_key|
    API.user(user_key, request.params)
  end
end
