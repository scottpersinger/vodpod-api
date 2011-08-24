class API::MainController
  # Followers
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS
  h 'users', :*, 'followers' do |user_key|
    d = API.user(user_key).followers_dataset.api_filter(request.params)
    a = NamedArray.new('followers', d.all)
    a.total = d.unlimited.select(:users__id).count
    a
  end
end
