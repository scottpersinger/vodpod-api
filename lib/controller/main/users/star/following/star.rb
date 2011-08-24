class API::MainController
  # A specific user you're following
  cache_with RECORD_CACHE_KEYS
  h 'users', :*, 'following', :* do |user_key, target_key|
    unless u = API.user(user_key).following_dataset.api_get(target_key).api_filter(request.params).first
      raise API::Error, "not following user (#{target_key})"
    end

    u    
  end
end
