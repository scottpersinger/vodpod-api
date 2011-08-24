class API::MainController
  # Videos for a user
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS + TAG_CACHE_KEYS, :ttl => 5
  h 'users', :*, 'videos' do |user|
    API.videos user, request.params
  end
end
