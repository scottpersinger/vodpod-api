class API::MainController
  # Search in all a user's collections
  cache_with RECORD_CACHE_KEYS + PAGE_CACHE_KEYS + SEARCH_CACHE_KEYS
  h 'users', :*, 'search' do |user|
    params = {'user' => user}.merge(request.params)
    API.search(request[:query], params)
  end
end
