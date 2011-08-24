class API::MainController
  # Followed users
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS
  h 'users', :*, 'following' do |user_key|
    d = API.user(user_key).following_dataset.api_filter(request.params)
    a = NamedArray.new('following', d.all)
    a.total = d.unlimited.select(:users__id).count
    a
  end
end
