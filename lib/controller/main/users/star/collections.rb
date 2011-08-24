class API::MainController
  # Show all collections for this user.
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS
  h 'users', :*, 'collections' do |user|
    API.collections(user, request.params)
  end
end
